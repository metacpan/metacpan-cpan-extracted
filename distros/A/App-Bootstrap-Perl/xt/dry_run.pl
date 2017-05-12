use strict;
use File::Basename;
use Symbol; 
use Test::More;

our @data; chomp(@data = <DATA>);
our $user;
our $last_cmd;
our $last_line;

our $code_top = <<'CODE1';
BEGIN {
        use subs 'open', 'system';

        sub open (*;$@) {
                &core_open;
        }
        
        sub system {
                &core_system;
        }
};
CODE1

our $code_bottom = <<'CODE2';
BEGIN {
        no warnings; # sub redefined       
        *print_and_system       = \&test_cmd;
        *print_and_system_out   = \&test_cmd;
        *print_and_qx           = \&test_cmd;
        *setup_user             = sub {};
        *setup_log              = sub {};

        CORE::open($USER, ">", \$user) || die;

        data_setvars();
};
CODE2

sub dry_run {
        # read bootstrap-perl code
        my $app_path = dirname($0)."/../bin/bootstrap-perl";
        open(my $fh, "<", $app_path) || die;
        sysread($fh, my $code, -s $fh) || die;
        
        # reopen DATA handle
        my $appdata;
        $code =~ s/__DATA__\n(.*)$//s;
        $appdata = $1;
        open(DATA, "<", \$appdata) || die; 
        
        # add top and bottom code
        $code =~ s/=cut\n/$&$code_top/s;
        $code .= $code_bottom;

       # run app
        eval $code;
        die $@ if $@;
}

sub data_setvars {
        while ($data[0] =~ /^[\@|\$]/) {
                my $varcode = shift(@data);
                eval $varcode;
        }
}

sub data_testcond {
        while ($data[0] =~ /^=(.*)$/) {
                my $cond = $1;
                shift @data; data_skip(); # to show next cmd on fail
                no strict 'vars';
                ok eval($cond) or do {
                        diag("see bootstrap-perl:$last_line\n".
                                "last cmd=[$last_cmd]\n".
                                "failed condition=[$cond]\n".
                                "\$@=[$@]\n".
                                "next expected=[$data[0]]"
                                );
                        die;
                }
        }
}

sub data_skip {
        while ($data[0] eq "" || substr($data[0],0,1) eq "#") { 
                @data > 0 || return;
                shift @data;
        }
}

sub data_next_cmd {
        data_skip;
        data_setvars;
        data_testcond;
        my $next = shift @data;
        $next;
}

sub data_next_out {
        my $out;
        data_skip;
        # may have several lines
        while ($data[0] =~ /^\< /) {
                # remove first "< "
                $out .= substr($data[0], 2)."\n";
                shift @data;
                data_skip;
        }
        $out; 
}

sub test_cmd {
        my $cmd = shift;
        # print "[test_cmd] $cmd\n";
        my $expected = data_next_cmd();

        $last_cmd = $cmd;
        $last_line = caller_line() - split(/\n/, $code_top);

        ok($cmd eq $expected) or do {
                diag("see bootstrap-perl:$last_line\n".
                        "cmd=[$cmd]\n".
                        "expected=[$expected]\n");
                die;                        
        };                
        data_next_out();
}

sub core_open {
        test_cmd("open $_[1] $_[2]");
  
        my $rw = $_[1];
        $rw = $rw eq '|-'? '>': $rw;

        my $io_buf;
        if(defined($_[0])) {
                CORE::open(qualify_to_ref($_[0]), $rw, \$io_buf) || die;
                
        } else {
                my $fh;
                CORE::open($fh, $rw, \$io_buf) || die;
                $_[0] = $fh;
        }
        
        1;
}

sub core_system {
        test_cmd(@_);
        0;
}

dry_run();

