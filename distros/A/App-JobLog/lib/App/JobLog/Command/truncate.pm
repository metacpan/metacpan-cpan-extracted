package App::JobLog::Command::truncate;
$App::JobLog::Command::truncate::VERSION = '1.042';
# ABSTRACT: decapitate the log


use App::JobLog -command;
use autouse 'App::JobLog::TimeGrammar' => qw(parse);
use Class::Autouse
  qw(IO::File App::JobLog::Log App::JobLog::Log::Line File::Temp File::Spec);
use autouse 'App::JobLog::Time'   => qw(now);
use autouse 'App::JobLog::Config' => qw(log dir);
use autouse 'File::Copy'          => qw(move);

use Modern::Perl;
no if $] >= 5.018, warnings => "experimental::smartmatch";

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $expression = join ' ', @$args;
    my ( $s, $is_interval );
    eval { ( $s, undef, $is_interval ) = parse $expression; };
    $self->usage_error($@) if $@;
    $self->usage_error('truncation date must not be a interval')
      if $is_interval;

    # determine name of head log
    my $log = App::JobLog::Log->new;
    my ($p) = $log->find_previous($s);
    $self->usage("no event in log prior to $expression") unless $p;
    my ($e) = $log->first_event;
    my $base = 'log-' . $e->start->ymd . '--' . $p->start->ymd;

    # create output handle for head log
    my $io =
      $opt->compression ? _pick_compression( $opt->compression ) : 'IO::File';
    my $suffix = '';
    my @args   = ();
    for ($io) {
        when ('IO::File') { push @args, 'w' }
        when ('IO::Compress::Zip') {
            $suffix = '.zip';
            push @args, Name => $base;
        }
        when ('IO::Compress::Gzip')  { $suffix = '.gz' }
        when ('IO::Compress::Bzip2') { $suffix = '.bz2' }
        when ('IO::Compress::Lzma')  { $suffix = '.lzma' }
        default { die "unprepared to handle $io; please report bug" };
    }
    my $old_f = File::Spec->catfile( dir, $base . $suffix );
    my $old_fh     = $io->new( $old_f, @args );
    my $fh         = File::Temp->new;
    my $current_fh = $old_fh;
    my $log_handle = IO::File->new( log, 'r' );
    my ( $unswitched, @buffer, $previous ) = (1);
    while ( defined( my $line = $log_handle->getline ) ) {
        my $ll = App::JobLog::Log::Line->parse($line);
        if ( $ll->is_event ) {
            if ($unswitched) {
                $previous = $ll if $ll->is_beginning;
                if ( $ll->time > $s ) {
                    if ($previous) {    # event spanning border
                        my $end_time = $s->clone->subtract( seconds => 1 );
                        $current_fh->print(
                            App::JobLog::Log::Line->new(
                                done => 1,
                                time => $end_time
                            )
                        );
                        $previous->time = $s;
                        $line = $previous->to_string . "\n";
                    }
                    $current_fh->close;
                    $current_fh = $fh;
                    _header( $base, $suffix, \@buffer );
                    $unswitched = undef;
                }
                elsif ( $ll->is_end ) {
                    $previous = undef;
                }
            }
            while (@buffer) {
                $current_fh->print( shift @buffer );
            }
            $current_fh->print($line);
        }
        else {
            push @buffer, $line;
        }
    }
    while (@buffer) {
        $current_fh->print( shift @buffer );
    }
    $current_fh->close;
    move( "$fh", log );
    print "truncated portion of log saved in $old_f\n";
}

sub validate {
    my ( $self, $opt, $args ) = @_;
    $self->usage_error('no time expression provided') unless @$args;
    if ( $opt->compression ) {
        my $alg = _pick_compression( $opt->compression );
        eval "require $alg";
        $self->usage_error(
            "$@: you must install $alg to use compression option --"
              . $opt->compression )
          if $@;
    }
}

sub usage_desc {
    '%c ' . __PACKAGE__->name . ' %o <date>';
}

sub abstract {
    'shorten the log to contain only those moments after a given date';
}

sub options {
    return (
        [
            compression => hidden => {
                one_of => [
                    [ 'zip|z',   'pass truncated head of log through zip', ],
                    [ 'gzip|g',  'pass truncated head of log through gzip', ],
                    [ 'bzip2|b', 'pass truncated head of log through bzip2', ],
                    [ 'lzma|l',  'pass truncated head of log through lzma', ],
                ]
            }
        ]
    );
}

sub full_description {
    <<END
Over time your log will fill with cruft: work no one is interested in any longer,
tags whose meaning you've forgotten. What you want to do at this point is chop off
all the old stuff, stash it somewhere you can find it if need be, and retain in
your active log only the more recent events. This is what truncate is for. You give
it a starting date and it splits your log into two with the active portion containing
all moments on that date or after. The older portion is retained in your joblog hidden
directory.
END
}

# comment header added to truncated log
sub _header {
    my ( $base, $suffix, $buffer ) = @_;
    unshift @$buffer,
      map { App::JobLog::Log::Line->new( comment => "$_\n" ) }
      <<END =~ /.*\S/mg; #<--- Global symbol "$base" requires explicit package name at (eval 1853) line 9.
Log file truncated on @{[now]}.
Head of log to be found in $base$suffix
END
}

# converts chosen compression opt into appropriate IO:: algorithm
sub _pick_compression {
    my $alg = shift;
    for ($alg) {
        when ('zip')   { return 'IO::Compress::Zip' }
        when ('gzip')  { return 'IO::Compress::Gzip' }
        when ('bzip2') { return 'IO::Compress::Bzip2' }
        when ('lzma')  { return 'IO::Compress::Lzma' }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Command::truncate - decapitate the log

=head1 VERSION

version 1.042

=head1 SYNOPSIS

 houghton@NorthernSpy:~$ job truncate -z 2010
 truncated portion of log saved in /home/houghton/.joblog/log-2009-01-12--2009-12-29.zip
 houghton@NorthernSpy:~$ unzip -l /home/houghton/.joblog/log-2009-01-12--2009-12-29.zip
 Archive:  /home/houghton/.joblog/log-2009-01-12--2009-12-29.zip
   Length      Date    Time    Name
 ---------  ---------- -----   ----
     56342  2011-08-28 16:07   log-2009-01-12--2009-12-29
 ---------                     -------
     56342                     1 file
 houghton@NorthernSpy:~$ head /home/houghton/.joblog/log
 # Log file truncated on 2011-08-28T16:07:35.
 # Head of log to be found in log-2009-01-12--2009-12-29.zip
 # 2010/01/01
 2010  1  1  0  0  0:Complyon:adding features to segmenter
 # 2010/01/02
 2010  1  1 16 40 45:DONE
 2010  1  2 14 12 19:Complyon:creating accuracy measurement rig
 2010  1  2 14 41  9:DONE
 2010  1  2 14 44  5:Complyon:creating accuracy measurement rig
 # 2010/01/03
 houghton@NorthernSpy:~$ 

=head1 DESCRIPTION

Over time your log will fill with cruft: work no one is interested in any longer,
tags whose meaning you've forgotten. What you want to do at this point is chop off
all the old stuff, stash it somewhere you can find it if need be, and retain in
your active log only the more recent events. This is what truncate is for. You give
it a starting date and it splits your log into two with the active portion containing
all moments on that date or after. The older portion is retained in your joblog hidden
directory.

=head1 SEE ALSO

L<App::JobLog::Command::edit>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
