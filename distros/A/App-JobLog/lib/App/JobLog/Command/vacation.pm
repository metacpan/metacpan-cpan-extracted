package App::JobLog::Command::vacation;
$App::JobLog::Command::vacation::VERSION = '1.042';
# ABSTRACT: controller for vacation dates

use Modern::Perl;
use App::JobLog -command;
use autouse 'App::JobLog::TimeGrammar'      => qw(parse);
use autouse 'App::JobLog::Vacation::Period' => qw(
  FLEX
  FIXED
  ANNUAL
  MONTHLY
);
use Class::Autouse qw(App::JobLog::Vacation);
no if $] >= 5.018, warnings => "experimental::smartmatch";

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $vacation = App::JobLog::Vacation->new;
    if ( $opt->modification ) {
        eval {
            for ( $opt->modification )
            {
                when ('add') {
                    my ( $s, $e ) = parse( $opt->add );
                    my $repeats;
                    for ( $opt->{repeat} || '' ) {
                        when ('annual')  { $repeats = ANNUAL }
                        when ('monthly') { $repeats = MONTHLY }
                        default          { $repeats = 0 };
                    }
                    my $flexibility;
                    for ( $opt->{flexibility} || '' ) {
                        when ('fixed') { $flexibility = FIXED }
                        when ('flex')  { $flexibility = FLEX }
                        default        { $flexibility = 0 };
                    }
                    $vacation->add(
                        description => join( ' ', @$args ),
                        time        => $s,
                        end         => $e,
                        repeats     => $repeats,
                        type        => $flexibility,
                        tags => $opt->{tag} || [],
                    );
                }
                when ('remove') {
                    $vacation->remove( $opt->remove );
                }
            }
        };
        $self->usage_error($@) if $@;
    }
    _show($vacation);
    $vacation->close;
}

sub _show {
    my ($vacation) = @_;
    my $lines = $vacation->show;
    if (@$lines) {
        print $_ for @$lines;
    }
    else {
        say 'no vacation times recorded';
    }
}

sub usage_desc { '%c ' . __PACKAGE__->name . ' %o [<description>]' }

sub abstract { 'list or define days off' }

sub options {
    return (
        [ 'list|l', 'show all vacation times recorded', ],
        [
            'flexibility' => hidden => {
                one_of => [
                    [
                        'flex|f',
'add sufficient vacation time to complete workday; this is recorded with the "flex" tag'
                    ],
                    [
                        'fixed|x',
'a particular period of time during the day that should be marked as vacation; '
                          . 'this is in effect a special variety of work time, since it has a definite start and duration'
                    ],
                ]
            }
        ],
        [ 'tag|t=s@', 'tag vacation time; e.g., -a yesterday -t float' ],
        [
            'repeat' => 'hidden' => {
                one_of => [
                    [ 'annual',  'vacation period repeats annually' ],
                    [ 'monthly', 'vacation period repeats monthly' ],
                ]
            }
        ],
        [
            'modification' => 'hidden' => {
                one_of => [
                    [ 'add|a=s', 'add date or range; e.g., -a "May 17, 1951"' ],
                    [
                        'remove|r=i',
'remove period with given index from list (see --list); e.g., -r 1'
                    ],
                ]
            }
        ]
    );
}

sub validate {
    my ( $self, $opt, $args ) = @_;

    if ( $opt->modification ) {
        $self->usage_error('either list or modify') if $opt->list;
        $self->usage_error('no description provided')
          if $opt->modification eq 'add'
              && !@$args;
    }
    else {
        $self->usage_error('--tag requires that you add a date')
          if $opt->tag;
        $self->usage_error('--annual and --monthly require --add')
          if $opt->repeat;
        $self->usage_error('either list or modify') unless $opt->list;
        $self->usage_error('both --flex and --fixed require --add')
          if $opt->flexibility;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Command::vacation - controller for vacation dates

=head1 VERSION

version 1.042

=head1 SYNOPSIS

 houghton@NorthernSpy:~$ job vacation --help
 job <command>
 
 job vacation [-aflrtx] [long options...] [<description>]
 	-l --list       show all vacation times recorded
 	-f --flex       add sufficient vacation time to complete workday;
 	                this is recorded with the "flex" tag
 	-x --fixed      a particular period of time during the day that
 	                should be marked as vacation; this is in effect a
 	                special variety of work time, since it has a definite
 	                start and duration
 	-t --tag        tag vacation time; e.g., -a yesterday -t float
 	--annual        vacation period repeats annually
 	--monthly       vacation period repeats monthly
 	-a --add        add date or range; e.g., -a "May 17, 1951"
 	-r --remove     remove period with given index from list (see
 	                --list); e.g., -d 1
 	--help          this usage screen
 houghton@NorthernSpy:~$ job v --list
 no vacation times recorded
 houghton@NorthernSpy:~$ job v --add today job day
 1) 2011-03-07   job day
 houghton@NorthernSpy:~$ job v -a 15 --monthly Ides
 1)         15 monthly  Ides   
 2) 2011-03-07          job day
 houghton@NorthernSpy:~$ job v -a "Feb 13 through 15" --annual Lupercalia
 Feb 13 -- Feb 15 annual  Lupercalia conflicts with existing period 15 monthly  Ides at /home/houghton/perl5/lib/perl5/App/JobLog/Command/vacation.pm line 41
 1)               15 monthly  Ides      
 2) Feb 13 -- Feb 15 annual   Lupercalia
 3)       2011-03-07          job day   
 houghton@NorthernSpy:~$ job today
 Monday,  7 March, 2011
   8:01 am - ongoing  2.09  bar, foo  something to add; and still more                                                                                                  
            vacation  8.00            job day                                                                                                                           
 
   TOTAL HOURS 10.09
   VACATION     8.00
   UNTAGGED     8.00
   bar          2.09
   foo          2.09
 houghton@NorthernSpy:~$ job v -l
 1)               15 monthly  Ides      
 2) Feb 13 -- Feb 15 annual   Lupercalia
 3)       2011-03-07          job day   
 houghton@NorthernSpy:~$ job v --remove 3
 1)               15 monthly  Ides      
 2) Feb 13 -- Feb 15 annual   Lupercalia
 houghton@NorthernSpy:~$ job t
 Monday,  7 March, 2011
   8:01 am - ongoing  2.09  bar, foo  something to add; and still more                                                                                                  
 
   TOTAL HOURS 2.09
   bar         2.09
   foo         2.09
 houghton@NorthernSpy:~$ job v -a today --flex job day
 1)               15 monthly  Ides      
 2) Feb 13 -- Feb 15 annual   Lupercalia
 3)       2011-03-07 flex     job day   
 houghton@NorthernSpy:~$ job t
 Monday,  7 March, 2011
   8:01 am - ongoing  3.07  bar, foo  something to add; and still more                                                                                                  
            vacation  4.93            job day                                                                                                                           
 
   TOTAL HOURS 8.00
   VACATION    4.93
   UNTAGGED    4.93
   bar         3.07
   foo         3.07

=head1 DESCRIPTION

B<App::JobLog::Command::vacation> allows you to include time off in your summaries of work events. In most cases time off --
holidays, vacation, sick days, etc. -- are a completely different entity from work log events. They are the equivalent of
a number of hours of work but these hours don't have a defined start or end, they may repeat at predictable intervals, and
in some cases their duration is flexible, stretching or shrinking depending on how much actual time you work in the day. On
the other hand, sometimes you want to report time off just as you do a regular event, giving it a fixed start and end time
and hence duration. Because of the peculiar nature of time off, and because it can overlap regular events in ill-defined
ways, vacation time is stored in its own file, F<.joblog/vacation>. This is the least human readable of the files used by
L<App::JobLog>, but still it isn't too bad:

 houghton@NorthernSpy:~$ cat ~/.joblog/vacation 
 2011  2 15  0  0  0:2011  2 15 23 59 59:02::Ides
 2011  2 13  0  0  0:2011  2 15 23 59 59:01::Lupercalia
 2011  3  7  0  0  0:2011  3  7 23 59 59:10::job day

If you wish to understand this format you can look at the code for L<App::JobLog::Vacation::Period>, but in general you
should use B<App::JobLog::Command::vacation> to modify this file.

=head2 CATEGORIES OF TIME OFF

=over 8

=item repetition

Most time off occurs in a fixed interval of a fixed year. All time off is representable this way. For convenience, though,
one may also specify that a period repeats annually or monthly.

=item flexibility

Most intervals of time off give you the expected number of work hours per day that would otherwise be a work day. One may
also mark a vacation period as fixed or flexible, however. A fixed period behaves in every way like a work event except
it doesn't appear in the work log. A flexible vacation period shrinks or expands as needed to fill out the hours to the
full complement in the days in which they occur.

=back

=head2 SORT ORDER

When sorted among themselves, monthly intervals sort before annual which sort before fixed. Ordinary events sort before
all vacation events except fixed time off, which sorts as an ordinary event.

=head1 SEE ALSO

L<App::JobLog::Command::today>, L<App::JobLog::Command::summary>, L<App::JobLog::Vacation>, L<App::JobLog::Vacation::Period>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
