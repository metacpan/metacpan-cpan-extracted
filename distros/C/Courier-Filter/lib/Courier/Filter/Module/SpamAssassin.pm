#
# Courier::Filter::Module::SpamAssassin class
#
# (C) 2005-2008 Julian Mehnle <julian@mehnle.net>
# $Id: SpamAssassin.pm 211 2008-03-23 01:25:20Z julian $
#
###############################################################################

=head1 NAME

Courier::Filter::Module::SpamAssassin - SpamAssassin message filter module for
the Courier::Filter framework

=cut

package Courier::Filter::Module::SpamAssassin;

use warnings;
use strict;

use base 'Courier::Filter::Module';

use Mail::SpamAssassin;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

=head1 SYNOPSIS

    use Courier::Filter::Module::SpamAssassin;

    my $module = Courier::Filter::Module::SpamAssassin->new(
        prefs_file  => '/etc/courier/filters/courier-filter-spamassassin.cf',
        sa_options  => {
            # any Mail::SpamAssassin options
        },
        
        logger      => $logger,
        inverse     => 0,
        trusting    => 0,
        testing     => 0,
        debugging   => 0
    );

    my $filter = Courier::Filter->new(
        ...
        modules     => [ $module ],
        ...
    );

=head1 DESCRIPTION

This class is a filter module class for use with Courier::Filter.  It matches a
message if its SpamAssassin spam score exceeds the configured threshold.

=cut

# Implementation:
###############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Courier::Filter::Module::SpamAssassin>

Creates a new B<SpamAssassin> filter module.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<prefs_file>

The path of a SpamAssassin preferences file.  If this option is specified, its
value is passed to L<< the Mail::SpamAssassin constructor's C<userprefs_filename>
option | Mail::SpamAssassin/userprefs_filename >>.  If B<undef>, SpamAssassin
is instructed not to read any preferences besides its default configuration
files.  Defaults to B<undef>.

=item B<sa_options>

A hash-ref specifying options for the Mail::SpamAssassin object used by this
filter module.  See L<Mail::SpamAssassin/new> for the supported options.

=back

All options of the B<Courier::Filter::Module> constructor are also supported.
Please see L<Courier::Filter::Module/new> for their descriptions.

=cut

sub new {
    my ($class, %options) = @_;
    
    my $use_user_prefs = defined($options{prefs_file});
    $options{sa_options}->{userprefs_filename} = $options{prefs_file};

    my $spamassassin = Mail::SpamAssassin->new( $options{sa_options} );
    $spamassassin->compile_now($use_user_prefs);
    
    my $self = $class->SUPER::new(
        %options,
        spamassassin    => $spamassassin
    );
    
    return $self;
}

=back

=head2 Instance methods

See L<Courier::Filter::Module/"Instance methods"> for a description of the
provided instance methods.

=cut

sub match {
    my ($self, $message) = @_;
    
    my $spamassassin    = $self->{spamassassin};
    my $sa_message      = $spamassassin->parse($message->text);
    my $status          = $spamassassin->check($sa_message);
    
    my $is_spam         = $status->is_spam;
    my $score           = $status->get_score;
    my $tests_hit       = $status->get_names_of_tests_hit;
    
    $status->finish();
    $sa_message->finish();
    
    return 'SpamAssassin: Message looks like spam (score: ' . $score . '; ' . $tests_hit . ')'
        if $is_spam;
    
    return undef;
        # otherwise.
}

=head1 SEE ALSO

L<Courier::Filter::Module>, L<Courier::Filter::Overview>.

For AVAILABILITY, SUPPORT, COPYRIGHT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
