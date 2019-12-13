package App::TimeTracker::Command::Billing;
use strict;
use warnings;
use 5.010;

# ABSTRACT: Add a billing point as a tag to tasks

our $VERSION = "1.000";

use Moose::Role;
use DateTime;

sub munge_billing_start_attribs {
    my ( $class, $meta, $config ) = @_;
    my $billing = $config->{billing};
    my %attr    = (
        isa           => 'Str',
        is            => 'ro',
        documentation => 'Billing',
    );
    $attr{required} = 1 if $billing->{required};

    if ( my $default = $billing->{default} ) {
        if ( $default eq 'strftime' ) {
            my $format = $billing->{strftime};
            $attr{default} = sub {
                return DateTime->now->strftime($format);
            }
        }
    }

    $meta->add_attribute( 'billing' => \%attr );
}

after '_load_attribs_start'    => \&munge_billing_start_attribs;
after '_load_attribs_append'   => \&munge_billing_start_attribs;
after '_load_attribs_continue' => \&munge_billing_start_attribs;

before [ 'cmd_start', 'cmd_continue', 'cmd_append' ] => sub {
    my $self = shift;

    $self->add_tag( $self->billing ) if $self->billing;
};

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TimeTracker::Command::Billing - Add a billing point as a tag to tasks

=head1 VERSION

version 1.000

=head1 DESCRIPTION

Add a billing point to each task. Could be based on the current date (eg '2019/Q4' or '2019/11') or on some project name.

=head1 CONFIGURATION

=head2 plugins

Add C<Billing> to the list of plugins.

=head2 billing

add a hash named C<billing>, containing the following keys:

=head3 required

Set to a true value if 'billing' should be a required command line option

=head3 default

Set to the method to calculate the default billing point. Currently there is only one method implemented, C<strftime>

=head3 strftime

When using C<default = strftime>, specify the L<DateTime::strftime> format. Some examples:

=over

=item * C<%Y/%m> -> 2019/12

=item * C<%Y/Q%{quarter}> -> 2019/Q4

=back

=head1 NEW COMMANDS

no new commands

=head1 CHANGES TO OTHER COMMANDS

=head2 start, continue, append

=head3 --billing

    ~/perl/Your-Project$ tracker start --billing offer-42

Add a tag 'offer-42', which you can later use to filter all tasks
belonging to an offer / sub-project etc

If you set up a C<default> using C<strftime> you can automatically add
a billing tag for eg the current month or quarter. This is very
helpful for mapping tasks to maintainance contracts.

  cat .tracker.json
  "billing":{
      "required":false,
      "default": "strftime",
      "strftime": "%Y/Q%{quarter}"
  }

  ~/perl/Your-Project$ tracker start
  Started working on Your-Project (2019/Q4) at 22:26:07

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
