use 5.10.0;
package DBIx::Oracle::UpgradeUtf8;
use utf8;
use strict;
use warnings;
use Scalar::Util qw/looks_like_number/;

our $VERSION = 1.02;

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

DBIx::Oracle::UpgradeUtf8 - automatically upgrade Perl strings to utf8 before sending them to DBD::Oracle (DEPRECATED)

=head1 DESCRIPTION

This module is deprecated -- it has been replaced by L<DBIx::AutoUpgrade::NativeStrings>





