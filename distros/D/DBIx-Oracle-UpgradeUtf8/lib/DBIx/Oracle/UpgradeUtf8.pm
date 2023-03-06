use 5.10.0;
package DBIx::Oracle::UpgradeUtf8;
use utf8;
use strict;
use warnings;
use Scalar::Util qw/looks_like_number/;

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

sub new {
  my ($class, %options) = @_;

  # check validity of args
  my $error =  __PACKAGE__ . "->new()";
  for ($options{debug})       {!$_ or ref $_ eq 'CODE'  or die "$error: 'debug' should be a coderef"}
  for ($options{dbh_methods}) {!$_ or ref $_ eq 'ARRAY' or die "$error: 'dbh_methods' should be an arrayref"}
  for ($options{sth_methods}) {!$_ or ref $_ eq 'ARRAY' or die "$error: 'sth_methods' should be an arrayref"}

  # build object internals
  my $self = {
    debug       => delete $options{debug},
    dbh_methods => delete $options{dbh_methods} // \@default_dbh_methods,
    sth_methods => delete $options{sth_methods} // \@default_sth_methods,
   };

  # check that all options have been consumed
  my @invalid_options = keys %options;
  die "$error: invalid options : " . join " / ", @invalid_options if @invalid_options;

  # return object
  bless $self, $class;
}


sub inject_callbacks {
  my ($self, $dbh, @invalid_args) = @_;

  # check input args
  $dbh->isa('DBI::db') or die '->inject_callbacks() : arg is not a database handle';
  !@invalid_args       or die '->inject_callbacks() : too many args';

  # coderef to be installed as common callback for all methods. This is a closure on $debug.
  my $debug = $self->{debug};                 # Copy for easier reference. The coderef will be a closure on $debug.
  my $upgrade_string_args = sub {
    $debug->("$_ callback") if $debug;        # Note: $_ is the method name

    # all strings in @_ will be upgraded (in-place, not copies)
  ARG:
    foreach my $i (1  .. $#_) {               # start only at 1 because $_[0] is the DBI handle

      # if arg is undef or empty string or 0, there is nothing to do
      next ARG if !$_[$i];

      # if arg is a scalar and is a native string, upgrade it
      if (! ref $_[$i]) {
        next ARG if looks_like_number($_[$i]) or utf8::is_utf8($_[$i]);
        $debug->("upgrading arg [$i] ($_[$i])") if $debug;
        utf8::upgrade($_[$i]);
      }

      # if arg is an arrayref (used by the *_array methods), upgrade native strings in that array
      elsif (ref $_[$i] eq 'ARRAY') {
        for my $val (grep {$_ && !ref $_ && !looks_like_number($_) && !utf8::is_utf8($_)} @{$_[$i]}) {
          $debug->("upgrading string in array arg [$i] ($val)") if $debug;
          utf8::upgrade($val);
        }
      }
    }

    return; # must end with an empty return (see L<DBI> documentation)
  };

  # inject callbacks for $dbh methods and for $sth methods
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

1;


__END__

=encoding utf8

=head1 NAME

DBIx::Oracle::UpgradeUtf8 - automatically upgrade Perl strings to utf8 before sending them to DBD::Oracle

=head1 SYNOPSIS

  use DBI;
  use DBIx::Oracle::UpgradeUtf8;
  
  my $injector = DBIx::Oracle::UpgradeUtf8->new;
  my $dbh = DBI->connect(@oracle_connection_params); # see L<DBD::Oracle> for details
  $injector->inject_callbacks($dbh);
  
  # these strings are semantically equal, but have different internal representations
  my $str        = "il était une bergère";
  my $str_native = $str; utf8::downgrade($str_native);
  my $str_utf8   = $str; utf8::upgrade($str_utf8);
  
  # Check if strings passed to Oracle are equal
  my $sql = "SELECT CASE WHEN ?=? THEN 'EQ' ELSE 'NE' END FROM DUAL";
  my ($result) = $dbh->selectrow_array($sql, {}, $str_native, $str_utf8); # returns 'EQ'


=head1 DESCRIPTION

This module is a workaround for a deficiency in L<DBD::Oracle>.
As of v1.83, the driver doesn't comply
with this specification in the L<DBI> documentation :

=over

I<< Perl supports two kinds of strings: Unicode (utf8 internally) and
non-Unicode (defaults to iso-8859-1 if forced to assume an
encoding). Drivers should accept both kinds of strings and, if
required, convert them to the character set of the database being
used. Similarly, when fetching from the database character data that
isn't iso-8859-1 the driver should convert it into utf8. >>

=back

DBD drivers like L<DBD::Sqlite> and L<DBD::Pg> comply with the specification:
non-Unicode strings in Perl programs are correctly encoded into utf8 before
being passed to the database. By contrast, L<DBD::Oracle> behaves as follows
when the client character set is Unicode (as set through the C<NLS_LANG> environment variable) :

=over

=item *

strings coming from the database are properly flagged as utf8 for Perl;

=item *

Perl Unicode strings are properly sent to the database;

=item *

Perl non-Unicode strings (i.e. without the utf8 flag) are B<not>
encoded into utf8 before being sent to the database. As a result,
characters in range 126-255 in native strings are not properly
treated on the server side.

=back

This problem has been signaled in a L<github issue|https://github.com/perl5-dbi/DBD-Oracle/issues/161>
and in a L<StackOverflow question|https://stackoverflow.com/questions/75245442/how-do-i-handle-unicode-with-dbdoracle>.
It is not clear when (if ever) it will be fixed.

The present module implements a workaround, thanks to the I<callbacks>
facility in L<DBI>'s architecture : callbacks intercept method calls
at the DBI level, and force all string arguments to be in utf8 before
passing them to L<DBD::Oracle>.

Actually this module could also be used with other DBD drivers;
in spite of the module's name, there is nothing in the code that is specially bound to Oracle.
I do not know if otther Perl DBD drivers suffer from the same deficiency.


=head1 METHODS

=head2 new

  my $injector = DBIx::Oracle::UpgradeUtf8->new(%options);

Constructor for a callback injector object. Options are :

=over

=item debug

An optional coderef that will be called as C<< $debug->($message) >>.
Default is C<undef>. A simple debug coderef could be :

  my $injector = DBIx::Oracle::UpgradeUtf8->new(debug => sub {warn @_, "\n"});


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

String arguments to DBI methods are modified through C<utf8::upgrade()>, which modifies
strings I<in-place>. It is very unlikely that this would affect your client program, but
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










