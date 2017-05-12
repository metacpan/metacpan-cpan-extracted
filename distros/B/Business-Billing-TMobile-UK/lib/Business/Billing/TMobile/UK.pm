=head1 MODULE FOR SALE

I am not planning to make any changes to this module as I have not been a
customer of TMobile for over a year. If someone would like to take over
maintenance/development of this module please get in touch.

=head1 ANTI-TMOBILE RANT

TMobile's lax fraud prevention procedures allowed a random person in a random
part of the UK to buy a mobile phone contract at my parents address. TMobile
then started to demand money from my parents and ignored initial attempts to
explain that the person has a different name from the residents and has never
lived at their address. TMobile eventually, after much chasing, agreed to stop
demanding money that my family did not owe them, but they to date have not
properly apologied for their actions or explained how on earth this person was
able to setup the phone contract in the first place.

I encourage people not to use T-Mobile.

=head1 NAME

Business::Billing::TMobile::UK - The fantastic new Business::Billing::TMobile::UK!

=head1 SYNOPSIS

 use Business::Billing::TMobile::UK

=head1 DESCRIPTION

An interface to TMobile UK's website for getting allowance and billing
information.

=cut

package Business::Billing::TMobile::UK;

# pragmata
use strict;
use vars qw($VERSION);
use warnings;

# Standard Perl Library and CPAN modules
use Carp;
use Encode qw(from_to);
use HTML::TreeBuilder;
use WWW::Mechanize;

$VERSION = '0.16';


=head1 CLASS METHODS

=head2 new

 new(username => $username, password => $password)

=cut

sub new {
	my($class, %options) = @_;

	foreach my $opt (qw(username password)){
		croak "Option $opt not provided\n" unless $options{$opt};
	}

	my $self = {
		username => $options{username},
		password => $options{password},
	};

	bless $self, $class;
	return $self;
}

=head1 OBJECT METHODS

=head2 get_allowances

 get_allowances()

Logs into the My Account section of the T-Mobile website and parses out the
Allowance information if available.

=cut

sub get_allowances {
	my($self) = @_;

	my $content = $self->_login();

	return $self->_parse_allowances($content);
}

# PRIVATE METHODS

sub _login {
	my($self) = @_;

	my $agent = WWW::Mechanize->new();
  $agent->get('http://www.t-mobile.co.uk/Dispatcher');
  $agent->form_name('login');
	$agent->current_form->value('username', $self->{username});
  $agent->current_form->value('password',  $self->{password});
  $agent->submit();
	return $agent->content;

}

sub _logout {
	croak "Not implemented yet\n";
}

sub _parse_allowances {
	my($self, $html) = @_;

	# Build Tree
	my $tree = HTML::TreeBuilder->new_from_content($html);

	# Find the td tag with the news stories in it
	# Thankfully it has a width which no other 
	my @tags = $tree->look_down(_tag => 'tr', id=> 'allwValueRow');

	croak "Allowances not found on T-Mobile site at present time\n" unless @tags;

	my @text = grep {!/^$/ } map {$_->as_text; } @tags;
	

	my @allowances;

	foreach my $text (@text) {
		from_to($text, 'utf8', 'iso-8859-1');
		# There seems to be some weird encoding. Most of it dissappears with the conversion from UTF-8 but there are also stray ? chars
		$text =~ s/^(\d+)[?](\D+)$/$1 $2/;
		push @allowances, $text;
	}

	return \@allowances;

}

1;

=head1 INSTALLATION

This module uses Module::Build for its installation. To install this module type
the following:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install


If you do not have Module::Build type:

  perl Makefile.PL

to fetch it. Or use CPAN or CPANPLUS and fetch it "manually".

=head1 DEPENDENCIES

This module requires these other modules and libraries:

 Test::More

Test::More is only required for testing purposes

This module has these optional dependencies:

 Test::Distribution

This is just requried for testing purposes.

=head1 TODO

If find this module useful please do let me know and I'll spend more effort on
expanding/improving it. All enhancement requests are welcome.

=over

=item *

_logout method (just to be nice)

=back

=head1 BUGS

To report a bug or request an enhancement use CPAN's excellent Request Tracker,
either via the web:

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-Billing-TMobile-UK>

or via email:

C<bug-business-billing-tmobile-uk@rt.cpan.org>

=head1 SOURCE AVAILABILITY

This source is part of a SourceForge project which always has the
latest sources in svn.

http://sourceforge.net/projects/sagar-r-shah/

=head1 AUTHOR

Sagar R. Shah, C<< <sagarshah@softhome.net> >>

=head1 COPYRIGHT

Copyright 2005 Sagar R. Shah, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
