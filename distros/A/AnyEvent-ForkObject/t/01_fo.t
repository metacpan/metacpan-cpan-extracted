#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 39;
use Encode qw(decode encode);

BEGIN {
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'AnyEvent';
    use_ok 'AnyEvent::ForkObject';
}


{
    my $cv = condvar AnyEvent;
    my $obj = new AnyEvent::ForkObject;

    ok $obj, "Constructor";

    my $phase = 0;

    $obj->do(require => 'Data::Dumper', cb => sub {
        $phase++;
        diag explain \@_ unless ok $_[0] eq 'ok', 'require Data::Dumper';
        $obj->do(
            module => 'Data::Dumper',
            args => [ [ 1, 2, 3 ]],
            cb => sub {
                my ($s, $o) = @_;
                diag explain \@_ unless ok $s eq 'ok', 'Data::Dumper created';
                $phase++;

                $o->Indent(0, sub { ok $_[0] eq 'ok', 'dumper->Indent(0)' });
                $o->Terse(1,  sub { ok $_[0] eq 'ok', 'dumper->Terse(1)'  });
                $o->Useqq(1,  sub { ok $_[0] eq 'ok', 'dumper->Useqq(1)'  });
                $o->Deepcopy(1,
                    sub { ok $_[0] eq 'ok', 'dumper->Deepcopy(1)' }
                );

                $o->Dump(sub {
                    my ($st, $ob) = @_;
                    undef $o;
                    $phase++;
                    ok $st eq 'ok', 'Dump has done';
                    ok $ob eq '123', 'Result is right';

                }, 0);
            });
    });

    $obj->do(require => 'File::Spec', cb => sub {
        diag explain \@_ unless ok $_[0] eq 'ok', 'require File::Spec';
        $phase++;
        $obj->do(
            module  => 'File::Spec',
            method  => 'catfile',
            args    => [ '/etc', 'passwd' ],
            cb      => sub {
                my ($s, $o) = @_;
                $phase++;
                ok $s eq 'ok', 'File::Spec->catfile has done';
                ok $o eq '/etc/passwd', 'File::Spec->catfile works properly';
            }
        );
    });


    my $timer = AE::timer 0.01, 0.01 => sub {
        return if $phase < 5;
        undef $obj; $cv->send
    };

    my $timeout; $timeout =
        AE::timer 2, 0 => sub { undef $obj; undef $timeout; $cv->send  };

    $cv->recv;

    ok $timeout, "Timeout wasn't reached";
}

{
    my $cv = condvar AnyEvent;
    my $obj = new AnyEvent::ForkObject;

    ok $obj, "Constructor";

    $obj->do(require => 'Data::Dumper', cb => sub {
        diag explain \@_ unless ok $_[0] eq 'ok', 'require Data::Dumper';
        $obj->do(
            module => 'Data::Dumper',
            args => [ [ 1, 2, 3 ]],
            cb => sub {
                my ($s, $o) = @_;

                ok $s eq 'ok', 'Data::Dumper created';

                undef $obj;

                $o->Dump(0, sub {
                    my ($st, $ob) = @_;
                    ok $st eq 'fatal', 'Object has been destroyed';
                    ok $ob =~ /destroyed/, 'Fatal message is right';

                });
            });
    });

    my $timer = AE::timer 1, 0 => sub {  $cv->send };

    $cv->recv;
}

{
    my $cv = condvar AnyEvent;
    my $obj = new AnyEvent::ForkObject;
    my $obj2 = new AnyEvent::ForkObject;

    ok $obj, "Constructor";

    kill KILL => $obj->{pid};
    waitpid $obj->{pid}, 0;
    $obj->do(require => 'Data::Dumper', cb => sub {
        diag explain \@_ unless  ok $_[0] eq 'fatal', 'Child was killed';
        my $t;
        $t = AE::timer 0.3, 0 => sub {
            undef $t;
            $cv->send;
        }
    });

    my $dont_call_if_destroyed = 1;
    $obj2->do(require => 'Data::Dumper', cb => sub {
        diag explain \@_;
        $dont_call_if_destroyed = 0;
    });
    kill KILL => $obj2->{pid};
    undef $obj2;

    my $timeout; $timeout = AE::timer 1, 0 => sub { undef $timeout; $cv->send };

    $cv->recv;

    ok $dont_call_if_destroyed, "Don't touch callbacks if destroyed";
    ok $timeout, "Timeout wasn't reached";
}


package FO_Test;

sub new
{
    bless { val => $_[1] } => __PACKAGE__;
}

sub val
{
    return $_[0]{val} if @_ == 1;
    return $_[0]{val} = $_[1];
}

package FO_Test2;

sub new
{
    bless [ 10, 20, $_[1] ] => __PACKAGE__;
}

sub val
{
    return $_[0][2] if @_ == 1;
    return $_[0][2] = $_[1];
}

package main;

{
    my $cv = condvar AnyEvent;
    my $obj = new AnyEvent::ForkObject;

    ok $obj, "Constructor";


    $obj->do(
        module => 'FO_Test',
        args => [ 123 ],
        cb => sub {
            my ($s, $o) = @_;
            ok $s eq 'ok', 'FO_Test constructor';

            $o->val(sub {
                my ($s, $v) = @_;
                ok $s eq 'ok' && $v == 123, "FO_Test->val";

                $o->val(234, sub {
                    my ($s, $v) = @_;
                    ok $s eq 'ok' && $v == 234, "FO_Test->val(234)";

                    $o->fo_attr(val => sub {
                        my ($s, $v) = @_;
                        ok $s eq 'ok' && $v == 234, "FO_Test->fo_attr('val')";

                        $o->fo_attr(val => 456 => sub {
                            my ($s, $v) = @_;
                            ok $s eq 'ok' && $v == 456,
                                "FO_Test->fo_attr('val' => 456)";

                            $o->val(sub {
                                my ($s, $v) = @_;
                                ok $s eq 'ok' && $v == 456, "FO_Test->val";
                            });
                        });

                    });

                });
            });

        });

    $obj->do(
        module => 'FO_Test2',
        args => [ 123 ],
        cb => sub {
            my ($s, $o) = @_;
            ok $s eq 'ok', 'FO_Test2 constructor';

            $o->val(sub {
                my ($s, $v) = @_;
                ok $s eq 'ok' && $v == 123, "FO_Test2->val";

                $o->val(234, sub {
                    my ($s, $v) = @_;
                    ok $s eq 'ok' && $v == 234, "FO_Test2->val(234)";

                    $o->fo_attr(0 => sub {
                        my ($s, $v) = @_;
                        ok $s eq 'ok' && $v == 10, "FO_Test2->fo_attr(0)";
                    });

                    $o->fo_attr(1 => sub {
                        my ($s, $v) = @_;
                        ok $s eq 'ok' && $v == 20, "FO_Test2->fo_attr(1)";
                    });

                    $o->fo_attr(2 => sub {
                        my ($s, $v) = @_;
                        ok $s eq 'ok' && $v == 234, "FO_Test2->fo_attr(2)";

                        $o->fo_attr(2 => 456 => sub {
                            my ($s, $v) = @_;
                            ok $s eq 'ok' && $v == 456,
                                "FO_Test2->fo_attr(2 => 456)";

                            $o->val(sub {
                                my ($s, $v) = @_;
                                ok $s eq 'ok' && $v == 456, "FO_Test2->val";
                            });
                        });

                    });
                });
            });
        });

    my $timer = AE::timer 0.5, 0 => sub {  $cv->send };

    $cv->recv;
}
