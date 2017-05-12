package Apache::Htpasswd::Perishable;

use strict;
use warnings;
use Apache::Htpasswd;
use Date::Simple qw(today);

our @ISA = qw(Apache::Htpasswd);

our $VERSION = '1.00';


# Preloaded methods go here.

sub new {
  my $class = shift;
  my $file = shift;

  my $self = bless {}, $class;

  system("touch $file") unless -f $file;
  unless(-f $file){
    $self->{'ERROR'} = __PACKAGE__. "::new Cannot create $file: $!";
    croak $self->error();
  }

#i hope he cleans this up.
  $self->{'PASSWD'} = $file;
  $self->{'ERROR'} = "";
  $self->{'LOCK'} = 0;
  $self->{'OPEN'} = 0;

  return $self;
}

sub extend {
  my ($self,$login,$days) = @_;

  die "provide a login" unless $login;
  die "provide a login" unless $days;

  $self->fetchInfo($login);
  my $current = Date::Simple->new($self->fetchInfo($login));
  die "Invalid date already exists.  Cannot extend: $!" unless $current;

  my $extended = $current + $days;

  $self->writeInfo($login,$extended) or die "couldn't set expiration date: ".$self->error;
  return 1;
}

sub expire {
  my ($self,$login,$days) = @_;

  die "provide a login" unless $login;
  unless(defined $days){
    my $expires = $self->fetchInfo($login);
    my $today = today();
    return $expires - $today;
  }

  my $date = today();
  my $expire = $date + $days;

  $self->writeInfo($login,$expire) or die "couldn't set expiration date: ".$self->error;
  return 1;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Apache::Htpasswd::Perishable - Perl extension for expiring htaccess entries

=head1 SYNOPSIS

  use Apache::Htpasswd::Perishable;

=head1 DESCRIPTION

This module allows you to define and extend an expiration date that is put into the 
extra-info field of an .htpasswd entry like:

  username:encrypted-password:extra-info


=head2 METHODS

This module inherits all methods from Apache::Htpasswd, and also adds:

expire() - expire($username,$days_from_today).  (over)writes the extra-info field
of an .htpasswd entry.  Calling expire($username) returns the number of days
until expiration.

extend() - extend($username,$days_from_expiration).  extends the expiration date
in the extra-info field of a .htpasswd entry by $days_from_expiration days.

=head1 AUTHOR

Allen Day <allenday@ucla.edu>

=head1 SEE ALSO

L<perl>. L<Apache::Htpasswd>. L<Date::Simple>.

=cut
