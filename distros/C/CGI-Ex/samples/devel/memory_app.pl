#!/usr/bin/perl -w

=head1 NAME

memory_app.pl - Test memory usage and benchmark speed comparison with CGI::Application

=cut

use Benchmark qw(cmpthese timethese);
use strict;

my $swap = {
    one   => "ONE",
    two   => "TWO",
    three => "THREE",
    a_var => "a",
    hash  => {a => 1, b => 2},
    code  => sub {"($_[0])"},
};

my $form = q{([% has_errors %])(<TMPL_VAR has_errors>)<form name=foo><input type=text name="bar" value=""><input type=text name="baz"></form>};
my $str_ht = $form . (q{Well hello there (<TMPL_VAR script_name>)} x 20) ."\n";
my $str_tt = $form . (q{Well hello there ([% script_name %])}      x 20) ."\n";

my $template_ht = \$str_ht;
my $template_tt = \$str_tt;

###----------------------------------------------------------------###
use Scalar::Util;
use Time::HiRes;
use CGI;
use CGI::Ex::Dump qw(debug);
use Template::Alloy load => 'Parse', 'Play', 'HTML::Template', 'Template';
$Template::VERSION = 2.18;
#use HTML::Template;

my $tests = {
    'C::A - bare' => sub {
        package FooBare;
        require CGI::Application;
        @FooBare::ISA = qw(CGI::Application);

        sub setup {
            my $self = shift;
            $self->start_mode('main');
            $self->mode_param(path_info => 1);
            $self->run_modes(main => sub { "Simple test" });
        }

        FooBare->new->run;
    },
    'C::E::A - bare' => sub {
        package FooBare;
        require CGI::Ex::App;
        @FooBare::ISA = qw(CGI::Ex::App);

        sub main_run_step {
            my $self = shift;
            print "Content-Type: text/html\r\n\r\n";
            #$self->cgix->print_content_type;
            print "Simple test";
            1;
        }

        FooBare->navigate({form => {}});
    },
    'Handwritten - bare' => sub {
        package FooBare2;

        sub new { bless {}, __PACKAGE__ }

        sub main {
            my $self = shift;
            print "Content-Type: text/html\r\n\r\n";
            print "Simple test";
        }

        FooBare2->new->main;
    },
    #'CGI::Prototype - bare' => sub {
    #    package FooBare;
    #    require CGI::Prototype;
    #},

    ###----------------------------------------------------------------###

    #'C::A - simple htonly' => sub {
    #    require CGI::Application;
    #    my $t = CGI::Application->new->load_tmpl($template_ht, die_on_bad_params => 0);
    #    $t->param(script_name => 2);
    #    print $t->output;
    #},
    #'C::E::A - simple htonly' => sub {
    #    require CGI::Ex::App;
    #    my $out = '';
    #    CGI::Ex::App->new->template_obj({SYNTAX => 'hte'})->process($template_ht, {script_name=>2}, \$out);
    #    print $out;
    #},

    'C::A - simple ht' => sub {
        package FooHT;
        require CGI::Application;
        @FooHT::ISA = qw(CGI::Application);

        sub setup {
            my $self = shift;
            $self->start_mode('main');
            $self->mode_param(path_info => 1);
            $self->run_modes(main => sub {
                my $self = shift;
                my $t = $self->load_tmpl($template_ht, die_on_bad_params => 0);
                $t->param('script_name', $0);
                return $t->output();
            });
        }

        FooHT->new->run;
    },
    'C::E::A - simple ht' => sub {
        package FooHT;
        require CGI::Ex::App;
        @FooHT::ISA = qw(CGI::Ex::App);

        sub main_file_print { $template_ht }
        sub template_args { {SYNTAX => 'hte'} } # , GLOBAL_CACHE => 1, COMPILE_PERL => 2} }
        sub fill_template {}
        sub print_out { my ($self, $step, $out) = @_; print "Content-Type: text/html\r\n\r\n$$out" }

        FooHT->navigate({no_history => 1, form => {}});
    },
    'C::A - simple tt' => sub {
        package FooTT;
        require CGI::Application;
        @FooTT::ISA = qw(CGI::Application);
        require CGI::Application::Plugin::TT;
        CGI::Application::Plugin::TT->import;

        sub setup {
            my $self = shift;
            $self->start_mode('main');

            $self->run_modes(main => sub {
                my $self = shift;
                return $self->tt_process($template_tt, {script_name => $0});
            });
        }

        FooTT->new->run;
    },
    'C::E::A - simple tt' => sub {
        package FooTT;
        require CGI::Ex::App;
        @FooTT::ISA = qw(CGI::Ex::App);
        sub main_file_print { $template_tt }
        sub fill_template {}
        sub print_out { my ($self, $step, $out) = @_; print "Content-Type: text/html\r\n\r\n$$out" }
        FooTT->navigate({no_history => 1, form => {}});
    },

    ###----------------------------------------------------------------###

    'C::A - complex ht' => sub {
        package FooComplexHT;
        require CGI::Application;
        @FooComplexHT::ISA = qw(CGI::Application);
        require CGI::Application::Plugin::ValidateRM;
        CGI::Application::Plugin::ValidateRM->import('check_rm');
        require CGI::Application::Plugin::FillInForm;
        CGI::Application::Plugin::FillInForm->import('fill_form');

        sub setup {
            my $self = shift;
            $self->start_mode('main');
            $self->mode_param(path_info => 1);
            $self->run_modes(main => sub {
                my $self = shift;
                my ($results, $err_page) = $self->check_rm('error_page','_profile');
                return $err_page if $err_page;
                die "Got here";
            });
        }

        sub error_page {
            my $self = shift;
            my $errs = shift;
            my $t = $self->load_tmpl($template_ht, die_on_bad_params => 0);
            $t->param('script_name', $0);
            $t->param($errs) if $errs;
            $t->param(has_errors => 1) if $errs;
            my $q = $self->query;
            $q->param(bar => 'BAROOSELVELT');
            return $self->fill_form(\$t->output, $q);
        }

        sub _profile { return {required => [qw(bar baz)], msgs => {prefix => 'err_'}} };

        FooComplexHT->new->run;
    },
    'C::E::A - complex ht' => sub {
        package FooComplexHT;
        require CGI::Ex::App;
        @FooComplexHT::ISA = qw(CGI::Ex::App);

        sub main_file_print { $template_ht }
        sub main_hash_fill  { {bar => 'BAROOSELVELT'} }
        sub main_hash_validation { {bar => {required => 1}, baz => {required => 1}} }
        sub main_finalize { die "Got here" }
        sub template_args { {SYNTAX => 'hte'} } # , GLOBAL_CACHE => 1, COMPILE_PERL => 2} }
        sub print_out { my ($self, $step, $out) = @_; print "Content-Type: text/html\r\n\r\n$$out" }

        local $ENV{'REQUEST_METHOD'} = 'POST';
        FooComplexHT->navigate({no_history => 1, form => {}});
    },
    'C::A - complex tt' => sub {
        package FooComplexTT;
        require CGI::Application;
        @FooComplexTT::ISA = qw(CGI::Application);
        require CGI::Application::Plugin::TT;
        CGI::Application::Plugin::TT->import;
        require CGI::Application::Plugin::ValidateRM;
        CGI::Application::Plugin::ValidateRM->import('check_rm');
        require CGI::Application::Plugin::FillInForm;
        CGI::Application::Plugin::FillInForm->import('fill_form');

        sub setup {
            my $self = shift;
            $self->start_mode('main');

            $self->run_modes(main => sub {
                my $self = shift;
                my ($results, $err_page) = $self->check_rm('error_page','_profile');
                return $err_page if $err_page;
                die "Got here";
            });
        }

        sub error_page {
            my $self = shift;
            my $errs = shift;
            my $out = $self->tt_process($template_tt, {script_name => $0, %{$errs || {}}, has_errors => ($errs ? 1 : 0)});
            my $q = $self->query;
            $q->param(bar => 'BAROOSELVELT');
            return $self->fill_form(\$out, $q);
        }

        sub _profile { return {required => [qw(bar baz)], msgs => {prefix => 'err_'}} };

        FooComplexTT->new->run;
    },
    'C::E::A - complex tt' => sub {
        package FooComplexTT;
        require CGI::Ex::App;
        @FooComplexTT::ISA = qw(CGI::Ex::App);
        sub main_file_print { $template_tt }
        sub main_hash_fill  { {bar => 'BAROOSELVELT'} }
        sub main_hash_validation { {bar => {required => 1}, baz => {required => 1}} }
        sub main_finalize { die "Got here" }
        sub print_out { my ($self, $step, $out) = @_; print "Content-Type: text/html\r\n\r\n$$out" }

        local $ENV{'REQUEST_METHOD'} = 'POST';
        FooComplexTT->navigate({no_history => 1, form => {}});
    },

    #'Template::Alloy - bare ht' => sub { require Template::Alloy; Template::Alloy->import('HTE') },
    #'Template::Alloy - bare tt' => sub { require Template::Alloy; Template::Alloy->import('TT') },
};

#perl -d:DProf samples/devel/memory_app.pl ; dprofpp tmon.out
#select($_) if open($_, ">>/dev/null");
$tests->{'C::E::A - complex tt'}->()
#    for 1 .. 1000
    ;
#exit;

###----------------------------------------------------------------###

my %_INC = %INC;
my @pids;
foreach my $name (sort keys %$tests) {
    my $pid = fork;
    if (! $pid) {
        $0 = "$0 - $name";
        my $fh;
        select($fh) if open($fh, ">>/dev/null");
        $tests->{$name}->() for 1 .. 1;
        sleep 1;
        select STDOUT;
        print "$name times: (@{[times]})\n";
        print "$name $_\n" foreach sort grep {! $_INC{$_}} keys %INC;
        sleep 15;
        exit;
    }
    push @pids, $pid;
}

sleep 2;
#    print "Parent - $_\n" foreach sort keys %INC;
print grep {/\Q$0\E/} `ps fauwx`;
kill 15, @pids;

###----------------------------------------------------------------###

exit if grep {/no_?bench/i} @ARGV;


foreach my $type (qw(bare simple complex)) {
    my $hash = {};
    open(my $fh, ">>/dev/null") || die "Can't access /dev/null: $!";
    foreach my $name (keys %$tests) {
        next if $name !~ /\b$type\b/;
        (my $copy = $name) =~ s/\s*\b$type\b//;
        $hash->{$copy} = sub {
            select $fh;
            $tests->{$name}->();
            select STDOUT;
        };
    }
    print "-------------------------------------------------\n";
    print "--- Testing $type\n";
    cmpthese timethese -2, $hash;
}

=head1 NOTES

Abbreviations:

  C::E::A - CGI::Ex::App
  C::A    - CGI::Application

The tests are currently run with the following code:

  use Template::Alloy load => 'Parse', 'Play', 'HTML::Template', 'Template';

This assures that CGI::Application will use the same templating system
as CGI::Ex::App so that template system issues don't affect overall
performance.  With the line commented out and CGI::Application using
HTML::Template (ht), C::A has a slight speed benefit, though it still
uses more memory.  With the line commented out and CGI::Application
using Template (tt), C::E::A is 2 to 3 times faster and uses a lot
less memory.

=head1 SAMPLE OUTPUT

  paul     23927  4.3  0.5   8536  6016 pts/1    S+   11:36   0:00  |       \_ perl samples/devel/memory_app.pl
  paul     23928  1.0  0.5   8988  5992 pts/1    S+   11:36   0:00  |           \_ samples/devel/memory_app.pl - C::A - bare
  paul     23929  2.0  0.6   9988  7152 pts/1    S+   11:36   0:00  |           \_ samples/devel/memory_app.pl - C::A - complex ht
  paul     23930  2.5  0.7  10172  7336 pts/1    S+   11:36   0:00  |           \_ samples/devel/memory_app.pl - C::A - complex tt
  paul     23931  1.0  0.5   8988  6024 pts/1    S+   11:36   0:00  |           \_ samples/devel/memory_app.pl - C::A - simple ht
  paul     23932  1.5  0.6   9308  6276 pts/1    S+   11:36   0:00  |           \_ samples/devel/memory_app.pl - C::A - simple tt
  paul     23933  0.0  0.5   8536  5200 pts/1    S+   11:36   0:00  |           \_ samples/devel/memory_app.pl - C::E::A - bare
  paul     23934  1.0  0.6   9328  6384 pts/1    S+   11:36   0:00  |           \_ samples/devel/memory_app.pl - C::E::A - complex ht
  paul     23935  1.0  0.6   9328  6392 pts/1    S+   11:36   0:00  |           \_ samples/devel/memory_app.pl - C::E::A - complex tt
  paul     23936  0.0  0.5   8536  5272 pts/1    S+   11:36   0:00  |           \_ samples/devel/memory_app.pl - C::E::A - simple ht
  paul     23937  0.0  0.5   8668  5344 pts/1    S+   11:36   0:00  |           \_ samples/devel/memory_app.pl - C::E::A - simple tt
  paul     23938  0.0  0.4   8536  5076 pts/1    S+   11:36   0:00  |           \_ samples/devel/memory_app.pl - Handwritten - bare
  -------------------------------------------------
  --- Testing bare
  Benchmark: running C::A -, C::E::A -, Handwritten - for at least 2 CPU seconds...
      C::A -:  3 wallclock secs ( 2.08 usr +  0.01 sys =  2.09 CPU) @ 3196.17/s (n=6680)
   C::E::A -:  3 wallclock secs ( 1.99 usr +  0.19 sys =  2.18 CPU) @ 6164.68/s (n=13439)
  Handwritten -:  1 wallclock secs ( 2.15 usr +  0.00 sys =  2.15 CPU) @ 266711.16/s (n=573429)
                    Rate        C::A -     C::E::A - Handwritten -
  C::A -          3196/s            --          -48%          -99%
  C::E::A -       6165/s           93%            --          -98%
  Handwritten - 266711/s         8245%         4226%            --
  -------------------------------------------------
  --- Testing simple
  Benchmark: running C::A - ht, C::A - tt, C::E::A - ht, C::E::A - tt for at least 2 CPU seconds...
   C::A - ht:  2 wallclock secs ( 2.04 usr +  0.00 sys =  2.04 CPU) @ 709.80/s (n=1448)
   C::A - tt:  2 wallclock secs ( 2.12 usr +  0.01 sys =  2.13 CPU) @ 600.47/s (n=1279)
  C::E::A - ht:  2 wallclock secs ( 2.14 usr +  0.01 sys =  2.15 CPU) @ 663.26/s (n=1426)
  C::E::A - tt:  3 wallclock secs ( 2.16 usr +  0.01 sys =  2.17 CPU) @ 589.40/s (n=1279)
                Rate C::E::A - tt    C::A - tt C::E::A - ht    C::A - ht
  C::E::A - tt 589/s           --          -2%         -11%         -17%
  C::A - tt    600/s           2%           --          -9%         -15%
  C::E::A - ht 663/s          13%          10%           --          -7%
  C::A - ht    710/s          20%          18%           7%           --
  -------------------------------------------------
  --- Testing complex
  Benchmark: running C::A - ht, C::A - tt, C::E::A - ht, C::E::A - tt for at least 2 CPU seconds...
   C::A - ht:  2 wallclock secs ( 2.00 usr +  0.00 sys =  2.00 CPU) @ 438.50/s (n=877)
   C::A - tt:  3 wallclock secs ( 2.16 usr +  0.00 sys =  2.16 CPU) @ 383.80/s (n=829)
  C::E::A - ht:  2 wallclock secs ( 2.14 usr +  0.01 sys =  2.15 CPU) @ 457.21/s (n=983)
  C::E::A - tt:  2 wallclock secs ( 2.13 usr +  0.00 sys =  2.13 CPU) @ 417.37/s (n=889)
                Rate    C::A - tt C::E::A - tt    C::A - ht C::E::A - ht
  C::A - tt    384/s           --          -8%         -12%         -16%
  C::E::A - tt 417/s           9%           --          -5%          -9%
  C::A - ht    438/s          14%           5%           --          -4%
  C::E::A - ht 457/s          19%          10%           4%           --

=cut
