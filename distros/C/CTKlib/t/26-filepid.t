#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use strict;
use warnings;
use Test::More qw/no_plan/;

use_ok qw/CTK::FilePid/;

# Regular mode
{
	my $pidfile = CTK::FilePid->new(file => "26test.regular.tmp");
	is $pidfile->pid, $$, 'current process by default';
	is $pidfile->write, $$, 'writing file';
	is $pidfile->running, $$, 'we are running';
	ok $pidfile->remove, 'deleted file';
}

# Autoremove mode
{
	my $pidfile = CTK::FilePid->new(file => "26test.auto.tmp", autoremove => 1);
	is $pidfile->write, $$, 'writing file';
	is $pidfile->running, $$, 'we are running';
}

# Fork mode
my $child;
my $file = '26test.child.tmp';
unlink $file if -e $file;
if ($child = fork) { # Parent
    waitpid $child, 0;
    my $cpf = CTK::FilePid->new(file => $file, autoremove => 1,);
    is $cpf->pid, $child, "$$:$child: child pid correct";
    ok !$cpf->running, 'child is not running';
    #ok $cpf->remove, 'removed child pid file';
} else { # child
    my $p = CTK::FilePid->new(
        file => $file,
        #pid  => $$,
    )->write; # hope for the best
    note "Child say: my pid is $p";
    #sleep 5;
}

1;

__END__

prove -lv t/26-filepid.t
