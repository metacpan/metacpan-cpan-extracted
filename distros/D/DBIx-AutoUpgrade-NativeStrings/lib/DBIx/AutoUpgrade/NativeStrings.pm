use 5.10.0;
package DBIx::AutoUpgrade::NativeStrings;
use utf8;
use strict;
use warnings;
use Scalar::Util qw/looks_like_number/;
use Encode       qw/decode/;
use DBI          (),

our $VERSION = 1.01;

my @default_dbh_methods = qw/do
                             prepare
                             selectrow_array
                             selectrow_arrayref
                             selectrow_hashref
                             selectall_arrayref
                             selectall_array
                             selectall_hashref
                             selectcol_arrayref/;

my @default_sth_methods = qw/bind_param
                             bind_param_array
                             execute
                             execute_array/;

my @sql_string_types    = (DBI::SQL_CHAR, DBI::SQL_VARCHAR, DBI::SQL_LONGVARCHAR, DBI::SQL_WLONGVARCHAR,
                           DBI::SQL_WVARCHAR, DBI::SQL_WCHAR, DBI::SQL_CLOB);


my %valid_options = (
# name                    expected reftype    default value
# ====                    ================    =============
  native              => ['NOREF' ,           'default'                    ],
  decode_check        => ['NOREF' ,                                        ],
  debug               => ['CODE'  ,                                        ],
  dbh_methods         => ['ARRAY' ,           \@default_dbh_methods        ],
  sth_methods         => ['ARRAY' ,           \@default_sth_methods        ],
  bind_type_is_string => ['ARRAY' ,           \&default_bind_type_is_string],
);



sub new {
  my ($class, %options) = @_;

  # build object internals, checking validity of input args and supplying default values
  my $self = {};
  while (my ($option, $details) = each %valid_options) {
    my ($expected_reftype, $default_val) = @$details;
    my $val = delete $options{$option};
    !$val or (ref $val || 'NOREF') eq $expected_reftype
          or die "$class->new(): '$option' should be a $expected_reftype";
    $val //= $default_val;
    $self->{$option} = $val if $val;
  }

  # check that there are no remaining input args
  my @invalid_options = keys %options;
  die "$class->new(): invalid options : " . join " / ", @invalid_options if @invalid_options;

  # make sure that Encode::Locale is loaded if needed
  require Encode::Locale if $self->{native} eq 'locale';

  # return object
  bless $self, $class;
}


sub inject_callbacks {
  my ($self, $dbh, @invalid_args) = @_;

  # check input args
  $dbh->isa('DBI::db') or die '->inject_callbacks() : arg is not a DBI database handle';
  !@invalid_args       or die '->inject_callbacks() : too many args';

  # coderef to be installed as common callback for all methods. This is a closure on $self.
  my $upgrade_string_args = sub {
    # NOTES: - here there is no unpacking of @_ because DBI callbacks must work directly on @_
    #        - $_ is the name of the DBI method

    # for calls to bind_param() with an explicit bind type, some types should be left untouched (for ex. SQL_BLOB)
    return if $_ eq 'bind_param' && $_[3] && !$self->{bind_type_is_string}->($_[3]);

    # vars to be used in the loop
    my $debug      = $self->{debug};          # copy just for easier reference
    my $debug_msg  = "$_ callback";
    my $do_upgrade = $self->{native} eq 'default' ? sub {utf8::upgrade($_[0])}
                                                  : sub {$_[0] = decode($self->{native}, $_[0], $self->{decode_check})};

    # loop over members of @_; start only at 1 because $_[0] is the DBI handle
  ARG:
    foreach my $i (1  .. $#_) {

      # if arg is undef or empty string or 0, there is nothing to do
      next ARG if !$_[$i];

      # if arg is a scalar and needs upgrading, do it
      if (! ref $_[$i]) {
        next ARG if dont_need_upgrade($_[$i]);
        $debug->("$debug_msg: upgrading arg [$i] ($_[$i])") if $debug;
        $do_upgrade->($_[$i]);
      }

      # if arg is an arrayref (used by the *_array methods), upgrade strings in that array
      elsif (ref $_[$i] eq 'ARRAY') {
        for my $val (grep {!dont_need_upgrade($_)} @{$_[$i]}) {
          $debug->("$debug_msg: upgrading string in array arg [$i] ($val)") if $debug;
          $do_upgrade->($val);
        }
      }
    }

    return; # must end with an empty return (see L<DBI> documentation)
  };

  # now inject the callback for $dbh methods and for $sth methods
  my $parent_callbacks = $dbh->{Callbacks}                   //= {};
  my $child_callbacks  = $parent_callbacks->{ChildCallbacks} //= {};
  inject_callback($parent_callbacks, $_ => $upgrade_string_args)  for @{$self->{dbh_methods}};
  inject_callback($child_callbacks,  $_ => $upgrade_string_args)  for @{$self->{sth_methods}};
}


sub inject_callback {
  my ($hash, $key, $coderef) = @_;

  # in case a previous callback was already installed, we replace it with a sub that combines both
  my $previous_cb = $hash->{$key};
  my $new_cb      = $previous_cb ? sub {&$coderef; &$previous_cb} : $coderef;

  $hash->{$key} = $new_cb;
}

sub dont_need_upgrade {
  my $scalar = shift;
                                     # no need to upgrade if ..
  return looks_like_number($scalar)  # .. it's a number
      || utf8::is_utf8($scalar)      # .. it's already a utf8 string
      || $scalar !~ /\P{ASCII}/;     # .. it only contains ASCII chars
}

sub default_bind_type_is_string {
  my $bind_type = shift;

  # according to L<DBI/bind_param>, the bind type can be given either as a scalar or as a hashref with a TYPE key
  $bind_type = $bind_type->{TYPE} if (ref $bind_type || '') eq 'HASH';

  return looks_like_number($bind_type) && grep {$bind_type == $_} @sql_string_types;
}

1;


__END__

=encoding utf8

=head1 NAME

DBIx::AutoUpgrade::NativeStrings - automatically upgrade Perl native strings to utf8 before sending them to the database

=head1 SYNOPSIS

  use utf8;
  use DBI;
  use DBIx::AutoUpgrade::NativeStrings;
  use Encode;
  
  my $injector = DBIx::AutoUpgrade::NativeStrings->new(native => 'cp1252');
  my $dbh = DBI->connect(@dbi_connection_params);
  $injector->inject_callbacks($dbh);
  
  # these strings are semantically equal, but have different internal representations
  my $str_utf8   = "il était une bergère, elle vendait ses œufs en ¥, ça paie 5¾ ‰ de mieux qu’en €",
  my $str_native = decode('cp1252', $str_utf8, Encode::LEAVE_SRC);
  
  # Oracle example : check if strings passed to the database are equal
  my $sql = "SELECT CASE WHEN ?=? THEN 'EQ' ELSE 'NE' END FROM DUAL";
  my ($result) = $dbh->selectrow_array($sql, {}, $str_native, $str_utf8); # returns 'EQ'


=head1 DESCRIPTION

This module intercepts calls to L<DBI> methods for automatically converting Perl native strings
to utf8 strings before they go to the DBD driver.

There are two situations where it is useful :

=over

=item 1.

Some DBD drivers I<do not comply> with this DBI specification :

=over

I<< Perl supports two kinds of strings: Unicode (utf8 internally) and
non-Unicode (defaults to iso-8859-1 if forced to assume an
encoding). Drivers should accept both kinds of strings and, if
required, convert them to the character set of the database being
used. Similarly, when fetching from the database character data that
isn't iso-8859-1 the driver should convert it into utf8. >>

=back

For example with L<DBD::Oracle> v1.83 and with a client charset set to C<AL32UTF8>,
native string with characters in the range 128 .. 255 are not converted to utf8 strings;
therefore characters in that range become Unicode code points in block
L<C1 control codes|https://en.wikipedia.org/wiki/C0_and_C1_control_codes>,
without any graphical display, which is not their intended meaning.

=item 2.

Drivers that I<do attempt to comply> with the DBI specification, like for
example L<DBD::SQLite> or L<DBD::Pg>, perform an automatic upgrade of
native strings ... assuming that the native character set is
iso-8859-1 (Latin-1). However some platforms have different native
character sets; in particular, the default "codepage" on Windows
machines is L<Windows-1252|https://fr.wikipedia.org/wiki/Windows-1252>, where
code points in the range 128-159 are mapped to various graphical
characters.  So if your native strings assume Windows-1252 encoding,
such characters will not be stored correctly within the database
server.

=back

With the present module, clients explicitly specify at initialization time
what is the native encoding.  From that, the module automatically
converts native strings to their proper Unicode counterpart before
sending them to the database.

Of course this only makes sense when the connection to the database
is in Unicode mode. Each DBD driver has its own specific way of
setting the character set used for the connection; so be sure
to properly tune your DBD driver when using the present module.


=head1 METHODS

=head2 new

  my $injector = DBIx::AutoUpgrade::NativeStrings->new(%options);

Constructor for a callback injector object. Options are :

=over

=item native

The name of the native encoding. This should be either

=over

=item * 

a valid Perl encoding name, as listed in L<Encode::Encodings>. Strings will be converted through L<Encode/decode>;

=item * 

the string C<'locale'>, which will invoke L<Encode::Locale> to automatically guess what is the native encoding;

=item * 

the string C<'default'>, which will use the default Perl upgrading mechanism through L<utf8/utf8::upgrade>.
This is the default value. It works well for latin-1 (iso-8859-1), but not for other native encodings.

=back



=item decode_check

A bitmask passed as third argument to L<Encode/decode> (see L<Encode/List of CHECK values>).
Default is C<undef>.


=item debug

An optional coderef that will be called as C<< $debug->($message) >>.
Default is C<undef>. A simple debug coderef could be :

  my $injector = DBIx::AutoUpgrade::NativeStrings->new(debug => sub {warn @_, "\n"});


=item dbh_methods

An optional arrayref containing the list of C<$dbh> method names that will receive a callback.
The default list is :

  do
  prepare
  selectrow_array
  selectrow_arrayref
  selectrow_hashref
  selectall_arrayref
  selectall_array
  selectall_hashref
  selectcol_arrayref

=item sth_methods

An optional arrayref containing the list of C<$sth> method names that will receive a callback.
The default list is :

  bind_param
  bind_param_array
  execute
  execute_array

=item bind_type_is_string

An optional coderef that decides what to do with calls to the ternary form of L<DBI/bind_param>, i.e.

  $sth->bind_param($position, $value, $bind_type);

If C<< $coderef->($bind_type) >> returns true, the C<$value> is treated as a string and will be
upgraded if needed, like arguments to other method calls; if the coderef returns false, the C<$value> is left intact.

The default coderef returns true when the C<$bind_type> is one of the DBI constants
C<SQL_CHAR>, C<SQL_VARCHAR>, C<SQL_LONGVARCHAR>, C<SQL_WLONGVARCHAR>, C<SQL_WVARCHAR>, C<SQL_WCHAR> or C<SQL_CLOB>.

=back




=head2 inject_callbacks

  $injector->inject_callbacks($dbh);

Injects callbacks into the given database handle.
If that handle already has callbacks for the same methods, the system will arrange for those
other callbacks to be called I<after> all string arguments have been upgraded to utf8.


=head1 ARCHITECTURAL NOTES

=head2 Object-orientedness

Although I'm a big fan of L<Moose> and its variants, the present module is implemented
in POPO (Plain Old Perl Object) : since the object model is extremely simple, there was
no ground for using a sophisticated object system.

=head2 Strings are modified in-place

String arguments to DBI methods are modified I<in-place>.
It is unlikely that this would affect your client program, but
if it does, you need to make your own string copies before passing them to the DBI methods.

=head2 Possible redundancies

L<DBI> does not precisely document which of its public methods call each other.
For example, one would think that C<execute()> internally calls C<bind_param()>, but this does
not seem to be the case. So, to be on the safe side, callbacks installed here make no assumptions
about string transformations performed by other callbacks. There might be some redundancies,
but it does no harm since strings are never upgraded twice.

=head2 Caveats

The C<bind_param_inout()> method is not covered -- the client program must do the proper updates
if that method is used to send strings to the database.

=head1 AUTHOR

Laurent Dami, E<lt>dami at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.










