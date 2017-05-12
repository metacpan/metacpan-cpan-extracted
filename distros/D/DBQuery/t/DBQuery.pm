package t::DBQuery;

use Test::Base -Base;
#use IPC::Run3 ();
use FindBin;
use Data::Dumper;

our @EXPORT = qw( run_tests );

$ENV{LC_ALL} = 'C';
my $is_linux = ($^O =~ /linux/i);

sub run_tests ()
{
    for my $block (blocks())
    {
        run_test($block);
    }
}

sub run_test ($)
{
    my $block = shift;
    my $name = $block->name;

    if (defined $block->linux_only && ! $is_linux)
    {
        diag "$name - Tests skipped on $^O\n";
        for (1..3)
        {
            pass("tests skipped on $^O\n");
        }
        return;
    }

    if (defined $block->connect)
    {
        eval { use DBQuery; };
        is(0, ($@ ? 1 : 0), "$name - status ok");
        my $cmd = "mysql -u" . $block->db_user . ($block->db_pass ? " -p" . $block->db_pass : "") . " " . $block->db_name . " -e 'show tables'";
        #eval { qx($cmd); };
        my $ret = system($cmd);
        #if ($@) 
        if ($ret)
        {
            pass("tests skipped because of username or password\n");
            return;
        }
        diag "\n" . $block->db_user . ' as database user';
        diag $block->db_pass . ' as database password';
#        warn Dumper $block->original_values;
        my $db = new DBQuery($block->original_values);
        eval { $db->connect(); };
        is(0, ($@ ? 1 : 0), "$name - status ok");
    }

#    my ($in, $out, $err);
#   IPC::Run3::run3 $cmd, \$in, \$out, \$err;
#    if (defined $block->err) 
#    {
#        $err =~ s/\Q$RcFile\E/**RC_FILE_PATH**/g;
#        is $err, $block->err, "$name - stderr ok";
#    }
#    elsif ($err)
#    {
#        warn $err, "\n";
#    }   

#    if (defined $block->out) 
#    {
#        $out =~ s/\Q$RcFile\E/**RC_FILE_PATH**/g;
#        is $out, $block->out, "$name - stdout ok";
#    }   
}

1;

