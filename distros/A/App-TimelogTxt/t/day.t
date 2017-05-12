#!/usr/bin/perl

use Test::Most tests => 12;
use Test::NoWarnings;

use Time::Local;
use App::TimelogTxt::Day;

{
    package Mock::Event;
    sub new
    {
        my ($class, $epoch, $project, $task) = @_;
        return bless { epoch => $epoch, project => $project, task => $task }, $class;
    }

    sub is_stop { return !$_[0]->{task}; }
    sub task { return $_[0]->{task}; }
    sub epoch { return $_[0]->{epoch}; }
    sub project { return $_[0]->{project}; }
}

throws_ok { App::TimelogTxt::Day->new } qr/Missing/, 'New without stamp should throw.';
throws_ok { App::TimelogTxt::Day->new( 'foo' ) } qr/Invalid/, 'New with invalid stamp should throw.';

{
    my $label = 'Initial Object';

    my $day = App::TimelogTxt::Day->new( '2012-06-01' );
    isa_ok( $day, 'App::TimelogTxt::Day', '$day' );

    ok( $day->is_empty, "$label: day should be empty at start" );

    my $buffer = '';
    open my $fh, '>>', \$buffer or die "Unable to make file handle: $!\n";
    $day->print_day_detail( $fh );
    is( $buffer, "\n2012-06-01  0:00\n", "$label: print_day_detail" );

    $buffer = '';
    $day->print_day_summary( $fh );
    is( $buffer, "2012-06-01  0:00\n", "$label: print_day_summary" );

    $buffer = '';
    $day->print_hours( $fh );
    is( $buffer, "2012-06-01:  0:00\n", "$label: print_hours" );
}

{
    my $label = 'Object';

    my $day = App::TimelogTxt::Day->new( '2012-06-30' );
    isa_ok( $day, 'App::TimelogTxt::Day', '$day' );
    my $time = 1372637679;
    $day->update_dur( undef, $time );
    $day->update_dur( Mock::Event->new( $time, '', '' ), $time+600 );

    my $buffer = '';
    open my $fh, '>>', \$buffer or die "Unable to make file handle: $!\n";
    $day->print_day_detail( $fh );
    is( $buffer, "\n2012-06-30  0:10\n", "$label: print_day_detail" );
}

{
    my $label = 'With Tasks';
    my $stamp = '2013-07-02';
    my $day = App::TimelogTxt::Day->new( $stamp );

    my $last;
    my $start = Time::Local::timelocal( 0, 0, 10, 2, 6, 113 );
    my @tasks = (
        Mock::Event->new( $start,     'proj1', 'Make changes' ),
        Mock::Event->new( $start+60,  'proj2', 'Start work' ),
        Mock::Event->new( $start+120, 'proj1', 'Make changes' ),
        Mock::Event->new( $start+180, 'proj1', '@Stuff Other changes' ),
        Mock::Event->new( $start+240, 'proj1', '@Stuff Other changes' ),
        Mock::Event->new( $start+300, 'proj1', '@Final' ),
        Mock::Event->new( $start+360, '', '' ),
    );
    foreach my $t (@tasks)
    {
        $day->update_dur( $last, $t->epoch );
        $day->start_task( $t );
        $last = $t;
    }

    my $buffer = '';
    open my $fh, '>>', \$buffer or die "Unable to make file handle: $!\n";
    $day->print_day_detail( $fh );
    my $expected = <<'EOR';

2013-07-02  0:06
  proj1         0:05
    Final                0:01
    Stuff                0:02 (Other changes)
    Make changes         0:02
  proj2         0:01
    Start work           0:01
EOR
    is( $buffer, $expected, "$label: print_day_detail" );

    $buffer = '';
    $day->print_day_summary( $fh );
    $expected = <<'EOR';
2013-07-02  0:06
  proj1         0:05
  proj2         0:01
EOR
    is( $buffer, $expected, "$label: print_day_summary" );
}
