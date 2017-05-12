package App::PM::Website::Command;
{
  $App::PM::Website::Command::VERSION = '0.131611';
}
#use App::Cmd::Setup -command;
use strict;
use warnings;
use base 'App::Cmd::Command';
use Config::YAML;
use POSIX qw(strftime);
use Data::Dumper;
use Date::Parse qw(str2time);
use DateTime::Format::Strptime;
use DateTime;
use Lingua::EN::Numbers::Ordinate qw(ordinate);

#ABSTRACT: Parent class for App::PM::Website commands

sub opt_spec
{
    my ( $class, $app ) = @_;
    return (
        $class->options($app),
        [ 'config-file=s' => "path to configuration file",
            { required => 1, default => "config/pm-website.yaml"}],
        [],
        [ 'help|h!'    => "show this help" ],
        [ 'dry-run|n!' => "take no action" ],
        [ 'verbose|v+' => "increase verbosity" ],
    );
}

sub validate_args
{
    my ( $self, $opt, $args ) = @_;
    die $self->_usage_text if $opt->{help};
    $self->validate_config( $opt, $args );
    $self->validate( $opt, $args );
}

sub validate_required_dir
{
    my ($self, $opt, $dir) = @_;
    my $c = $self->{config}{config}{website};
    $opt->{$dir} ||= $c->{$dir};
    die $self->usage_error("$dir is required")
        if !$opt->{$dir};

    die $self->usage_error(
        "$dir does not exist: $opt->{$dir}")
        if !-d $opt->{$dir};

    return 1
}
sub validate_or_create_dir
{
    my ($self, $opt, $dir) = @_;
    my $c = $self->{config}{config}{website};
    $opt->{$dir} ||= $c->{$dir};

    die $self->usage_error("$dir is required")
        if !$opt->{$dir};

    if ( ! -d $opt->{$dir} )
    {
        print "creating build dir: $opt->{$dir}\n"
            if $opt->{verbose};
        if ( !$opt->{dry_run} )
        {
            mkdir( $opt->{$dir} )
                or die $self->usage_error(
                "failed to make output directory $opt->{$dir} : $!");
        }
    }

    return 1
}


sub validate_config
{
    my ( $self, $opt, $args ) = @_;
    $self->{config} = Config::YAML->new( config => $opt->{config_file} )
        or die $self->usage_error("failed to open configuration file: $!");
}

sub meetings
{
    my $self = shift;
    my $meetings = $self->{config}->get_meetings;
    my $strp = new DateTime::Format::Strptime(
        pattern => '%Y-%b-%d',
        locale  => 'en',
    );
    my $strp_std = new DateTime::Format::Strptime(
        pattern => '%A %B %e, %Y',
        locale  => 'en',
    );
    my $strp_pretty = new DateTime::Format::Strptime(
        pattern => '%A the %e',
        locale  => 'en',
    );

    for my $meeting (@$meetings)
    {
        $meeting->{epoch} ||= str2time( $meeting->{event_date}, 'PST' );
        my $dt = DateTime->from_epoch( epoch => $meeting->{epoch} );
        $meeting->{dt} = $dt;
        $meeting->{ds1} ||= $strp->format_datetime($dt);
        $meeting->{ds_std} ||= $strp_std->format_datetime($dt);
        my $pretty = $strp_pretty->format_datetime($dt);
        $pretty =~ s/(\d+) \s* $/ordinate($1)/ex;
        $meeting->{event_date_pretty} = $pretty;
    }
    sort { $b->{epoch} <=> $a->{epoch} } @$meetings;
}

sub today
{
    my ($class) = @_;
    return unless $class;
    $class->date_as_ymd();
}

sub yesterday
{
    my ($class) = @_;
    return unless $class;
    $class->date_as_ymd( time - 24 * 60 * 60 );
}

sub date_as_ymd
{
    my ( $class, $time ) = @_;
    $time ||= time();
    return strftime( "%Y-%m-%d", localtime($time) );
}

1;

__END__
=pod

=head1 NAME

App::PM::Website::Command - Parent class for App::PM::Website commands

=head1 VERSION

version 0.131611

=head1 AUTHOR

Andrew Grangaard <spazm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Grangaard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

