package App::Standup::Role::Project;
use Object::Pad;
use Path::Tiny;
use Time::Seconds;

role Project {

  field $project_name :param :reader;

  # Unreleased, see #1
  method get_todo_tasks_from_yesterday {

    # Slurp the yesterday's template file
    my $yesterday = $self->date - Time::Seconds::ONE_DAY;
    my $formated_date = $self->build_path($yesterday->ymd('/'));
    #::p $yesterday;
    #::p $formated_date;
    # Keep all line between - todo and - blocking

  }

  # Unreleased see #1
  method get_yesterday_file_path {}

}


=head1 NAME

App::Standup::Role::Project - Project management for Standup::Diary

=head1 SYNOPSIS

  class App::Standup::Diary :does( Project ) { ... }

=head1 DESCRIPTION

It provides an L<Object::Pad> role with an only C<project_name>.

Any class implementing C<App::Standup::Role::Project> have a C<$self->project_name> instance
field.

=cut
