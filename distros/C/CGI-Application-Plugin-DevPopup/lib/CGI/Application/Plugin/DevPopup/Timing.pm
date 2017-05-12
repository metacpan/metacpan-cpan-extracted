package CGI::Application::Plugin::DevPopup::Timing;
{
  $CGI::Application::Plugin::DevPopup::Timing::VERSION = '1.08';
}

use strict;
use base qw/Exporter/;
use Time::HiRes qw/gettimeofday tv_interval/;
my $start = [gettimeofday];

sub import
{
    my $c = scalar caller;
    $c->add_callback( 'devpopup_report', \&_timer_report );
    $c->new_hook('devpopup_addtiming');
    $c->add_callback( 'devpopup_addtiming', \&_add_time );
    foreach my $stage (qw/ init prerun load_tmpl /)
    {
        $c->add_callback( $stage, sub { _add_time( shift(), $stage, @_ ) } );
    }
    goto &Exporter::import;
}

sub _timer_report
{
    my $app = shift;

    my $self = _new_or_self($app);
    unshift @$self, { dec => 'start', tod => $start };
    _add_time( $app, 'postrun' );
    $app->devpopup->add_report(
        title   => 'Timings',
        summary => 'Total runtime: ' . tv_interval( $self->[1]{tod}, $self->[-1]{tod} ) . ' sec.',
        report  => '<style>
            th { text-align:left; border-bottom:solid 1px black; }
            </style>' .
            'Application started at: ' . scalar( gmtime( $start->[0] ) ) . ' GMT<br/>' .
            '<table width="100%"><tr><th>From</th><th>To</th><th>Time taken</th></tr>' .
            join(
              $/,
              map {
                my $time = tv_interval( $self->[$_]{tod}, $self->[ $_ + 1 ]{tod} );
                "<tr><td>$self->[$_]{desc}</td><td>$self->[ $_ + 1 ]{desc}</td><td>$time sec.</td></tr>"
              } ( 1 .. $#$self - 1 )
            )
            . '</table>'
    );
}

sub _add_time
{
    my $app   = shift;
    my $stage = shift;
    $stage .= '(' . $_[-1] . ')' if $stage =~ /load_tmpl/;

    my $self = _new_or_self($app);
    push @$self, { desc => $stage, tod => [gettimeofday] };
}

sub _new_or_self
{
    my $app  = shift;
    my $self = $app->param('__CAP_DEVPOPUP_TIMER');
    unless ($self)
    {
        $self = bless [], __PACKAGE__;
        $app->param( '__CAP_DEVPOPUP_TIMER' => $self );
    }
    return $self;
}

1;    # End of CGI::Application::Plugin::DevPopup::Timing

__END__

=head1 NAME

CGI::Application::Plugin::DevPopup::Timing - show timing information about cgiapp stages

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    use CGI::Application::Plugin::DevPopup;
    use CGI::Application::Plugin::DevPopup::Timing;

    The rest of your application follows
    ...

Output will look roughly like this:

    Timings
    Total runtime: 3.1178 sec.
    Application started at: Thu Sep 22 02:55:35 2005

    From                        To                              Time taken
    -------------------------------------------------------------------------
    init                        prerun                          0.107513 sec.
    prerun                      before expensive operation      0.000371 sec.
    before expensive operation  after expensive operation       3.006688 sec.
    after expensive operation   load_tmpl(dp.html)              0.000379 sec.
    load_tmpl(dp.html)          postrun                         0.002849 sec.

=head1 ADD_TIMING

You can add your own timing points within your application by calling the hook at C<devpopup_addtiming> with a short label. The table above was created with the following code:

    $self->call_hook('devpopup_addtiming', 'before expensive operation');
    sleep 3;
    $self->call_hook('devpopup_addtiming', 'after expensive operation');

=head1 SEE ALSO

L<CGI::Application::Plugin::DevPopup>, L<CGI::Application>

=head1 AUTHOR

Rhesa Rozendaal, L<rhesa@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to
L<bug-cgi-application-plugin-devpopup@rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-DevPopup>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rhesa Rozendaal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
