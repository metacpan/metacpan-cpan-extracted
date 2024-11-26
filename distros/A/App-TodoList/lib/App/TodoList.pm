package App::TodoList;

use strict;
use warnings;

use JSON;
use File::HomeDir;
use File::Spec;

our $VERSION = '1.0.0'; 

sub new {
    my ($class, %args) = @_;

    my $home_dir = File::HomeDir->my_home;
    my $file = File::Spec->catfile($home_dir, '.tasks.json');

    my $self = {
        file  => $args{file} || $file,
        tasks => [],
    };

    bless $self, $class;

    $self->_load_tasks();
    return $self;
}

sub add_task {
    my ($self, $task) = @_;
    push @{ $self->{tasks} }, { task => $task, completed => 0 };
    $self->_save_tasks();
    return scalar @{ $self->{tasks} };
}

sub list_tasks {
    my ($self) = @_;
    return @{ $self->{tasks} };
}

sub complete_task {
    my ($self, $index) = @_;
    return 0 if $index < 1 || $index > scalar @{ $self->{tasks} };
    $self->{tasks}->[$index - 1]->{completed} = 1;
    $self->_save_tasks();
    return 1;
}

sub delete_task {
    my ($self, $index) = @_;
    return 0 if $index < 1 || $index > scalar @{ $self->{tasks} };
    splice @{ $self->{tasks} }, $index - 1, 1;
    $self->_save_tasks();
    return 1;
}

sub _load_tasks {
    my ($self) = @_;
    if (-e $self->{file}) {
        open my $fh, '<', $self->{file} or die "Could not open file '$self->{file}': $!";
        local $/;
        my $json = <$fh>;
        close $fh;
        $self->{tasks} = decode_json($json) if $json;
    }
}

sub _save_tasks {
    my ($self) = @_;
    open my $fh, '>', $self->{file} or die "Could not open file '$self->{file}': $!";
    print $fh encode_json($self->{tasks});
    close $fh;
}

1;
__END__

=encoding utf-8

=head1 NAME

todo_list - Simple command-line to-do list manager written in Perl.

=head1 SYNOPSIS

    todo_list [options]

=head1 DESCRIPTION

This script allows users to add, list, complete, and delete tasks, and saves the tasks in a JSON file located in the user's home directory.

=head1 OPTIONS

=over 4

=item --add <task_description>

Add a task.

Example:

    todo_list --add "Buy groceries"

=item --list

List all tasks.

Example:

    todo_list --list

=item --delete <task_number>

Delete a task.

Example:

    todo_list --delete 1

=item --complete <task_number>

Mark a task as completed.

Example:

    todo_list --complete 1

=item --help

Display this help message.

=back

=head1 ERRORS

If there is an error during any operation (such as adding, editing, or removing passwords), an error message will be displayed indicating the issue.

=head1 DEPENDENCIES

This script requires the L<Getopt::Long> module for command-line argument handling and the L<App::TodoList> module for password management operations.

=head1 AUTHOR

Luiz Felipe de Castro Vilas Boas <luizfelipecastrovb@gmail.com>

=head1 LICENSE

This module is released under the MIT License. See the LICENSE file for more details.

=cut
