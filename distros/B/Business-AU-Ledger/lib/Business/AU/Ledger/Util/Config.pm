package Business::AU::Ledger::Util::Config;

use Carp;

use Config::Tiny;

use Moose;

has config           => (is => 'rw', isa => 'Any', required => 0);
has config_file_path => (is => 'rw', isa => 'Str', required => 0);
has section          => (is => 'rw', isa => 'Str', required => 0);

use namespace::autoclean;

our $VERSION = '0.88';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;
	my($name) = '.htledger.conf';

	my($path);

	for (keys %INC)
	{
		next if ($_ !~ m|Business/AU/Ledger/Util/Config.pm|);

		($path = $INC{$_}) =~ s|Util/Config.pm|$name|;
	}

	$self -> init($path);

} # End of BUILD.

# -----------------------------------------------

sub init
{
	my($self, $path) = @_;

	$self -> config_file_path($path);

	# Check [global].

	$self -> config(Config::Tiny -> read($path) );
	$self -> section('global');

	if (! ${$self -> config}{$self -> section})
	{
		Carp::croak "Config file '$path' does not contain the section [@{[$self -> section]}]";
	}

	# Check [x] where x is host=x within [global].

	$self -> section(${$self -> config}{$self -> section}{'host'});

	if (! ${$self -> config}{$self -> section})
	{
		Carp::croak "Config file '$path' does not contain the section [@{[$self -> section]}]";
	}

	# Move desired section into config, so caller can just use $self -> config to get a hashref.

	$self -> config(${$self -> config}{$self -> section});

}	# End of init.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=head1 NAME

C<Business::AU::Ledger::Util::Config> - A helper for Business::AU::Ledger

=head1 Synopsis

	See docs for Business::AU::Ledger.

=head1 Description

C<Business::AU::Ledger::Util::Config> is a pure Perl module.

It reads lib/Business/AU/Ledger/.htledger.conf.

=head1 Constructor and initialization

Auto-generated code will create objects of type C<Business::AU::Ledger::Util::Config>. You don't need to.

=head1 Author

C<Business::AU::Ledger> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2009.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2008, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	the Artistic or the GPL licences, copies of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
