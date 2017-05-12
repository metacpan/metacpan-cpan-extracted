package App::Milter::Limit::PidFile;
$App::Milter::Limit::PidFile::VERSION = '0.52';
# ABSTRACT: Milter Limit Pid file class

use strict;
use Proc::PID::File;
use App::Milter::Limit::Config;
use App::Milter::Limit::Log;
use App::Milter::Limit::Util;

my $Pid;


sub running {
    my $class = shift;

    my $conf = App::Milter::Limit::Config->global;

    App::Milter::Limit::Util::make_path($$conf{state_dir});

    $Pid = Proc::PID::File->new;

    $Pid->file(dir => $$conf{state_dir});

    if ($Pid->alive) {
        $Pid = undef;
        return 1;
    }

    $Pid->touch;

    # chown the file so we can unlink it
    chown $$conf{user}, $$conf{group}, $Pid->{path};

    return 0;
}

1;

__END__

=pod

=head1 NAME

App::Milter::Limit::PidFile - Milter Limit Pid file class

=head1 VERSION

version 0.52

=head1 SYNOPSIS

 die "already running" if App::Milter::Limit::PidFile->running;

=head1 DESCRIPTION

This class manages the milter limit PID file.

=head1 METHODS

=head2 running

If the program is running already, returns true.  Otherwise, returns false,
and writes the pid file, and changes its permissions to the user/group
specified in the milter limit configuration file.  When the program exits, the
pid file will be removed automatically.

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/milter-limit>
and may be cloned from L<git://github.com/mschout/milter-limit.git>

=head1 BUGS

Please report any bugs or feature requests to bug-app-milter-limit@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=App-Milter-Limit

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
