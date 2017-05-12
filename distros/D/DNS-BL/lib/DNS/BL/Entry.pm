package DNS::BL::Entry;

use 5.006001;
use strict;
use warnings;

use NetAddr::IP 3;

our $VERSION = '0.00_01';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

sub new
{
    return bless 
    {
	addr	=> undef,
	desc	=> undef,
	value	=> '127.0.0.1',
	time	=> time,
    }, $_[0];
}

sub clone
{
    my $o = shift;
    my $n = __PACKAGE__->new;
    $n->$_($o->$_()) for qw/addr desc value time/;
    return $n;
}

# We'll let AUTOLOAD provide an accessor automatically for
# each parameter we get asked to produce.

sub AUTOLOAD
{
    no strict "refs";
    use vars qw($AUTOLOAD);
    my $method = $AUTOLOAD;
    $method =~ s/^.*:://;
    *$method = sub 
    { 
	my $self = shift;
	my $ret = $self->{$method};
	$self->{$method} = shift if @_;
	return $ret;
    };
    goto \&$method;
}

# The following accessors provide trivial tests over its arguments,
# so we provide them manually.

sub addr
{
    my $self = shift;
    my $ret = $self->{addr};
    if (@_)
    {
	my $ip = new NetAddr::IP shift;
	return $ret unless $ip;
	$self->{addr} = $ip;
    }
    return $ret;
}

sub time
{
    my $self = shift;
    my $ret = $self->{time};
    if (@_)
    {
	my $time = shift;
	return $ret unless $time =~ /^\d+$/;
	$self->{time} = $time;
    }
    return $ret;
}

1;
__END__

=head1 NAME

DNS::BL::Entry - An entry in a DNS black list

=head1 SYNOPSIS

  use DNS::BL::Entry;

=head1 DESCRIPTION

This is an internal class, used by L<DNS::BL>. Supported methods are:

=over

=item C<new()>

Creates a new C<DNS::BL::Entry> object, setting its C<time()> to the
current time and date.

=item C<clone()>

Creates a new C<DNS::BL::Entry> object with copies of all the values
stored within the original.

=item C<addr([ip address])>

Gets or sets the IP address or subnet this entry is supposed to match
with. It will accept any string that L<NetAddr::IP> would understand.

=item C<desc([description])>

Gets or sets the description associated with this entry. Note that
this text might be silently truncated by the storage backends.

=item C<value([value])>

Gets or sets the value associated to this entry. This is optional and
will default to 127.0.0.1 if left unspecified.

=item C<time([time and date of the entry])>

Gets or sets the time and date of this entry, in the traditional
"seconds since the epoch" unix time format. Defaults to the current
time and date when the object is created.

=back

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 0.00_01

Original version; created by h2xs 1.22

=back

=head1 SEE ALSO

Perl(1), DNS::BL(3), NetAddr::IP(3).

=head1 AUTHOR

Luis Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Luis Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
