package App::Standup::Diary::Template;

use Object::Pad;
use Mojo::Template;
use App::Standup::Role::Date;
use App::Standup::Role::Project;

class App::Standup::Diary::Template :does( Date ) :does( Project ) {

  method get_template {
    my $diary_template = <<~'END_TEMPLATE';
      # <%= $project_name %> <%= $today %>

      (C-c (C-o | C-d))
      [PRIORITIES](<%= $priorities_date %>-00_priorities.md)

      - done
      - todo
      - blocking

      END_TEMPLATE

    return $diary_template;
  }

  method render {
    my $mt = Mojo::Template->new(auto_escape => 1);
    my $month = $self->date->mon;
    my $month_numeric = $self->date->mon < 10 ? "0$month" : $month;
    return $mt->vars(1)->render(
      $self->get_template, {
        priorities_date => $self->date->year . '-' . $month_numeric,
        project_name    => $self->project_name,
        today           => $self->date->ymd
      });
  }
}


=head1 NAME

App::Standup::Diary::Template - Diary entry markdown template

=head1 SYNOPSIS

  my $template = App::Standup::Diary::Template->new(
    date         => $self->date,
    project_name => $self->project_name
  ));

  $template->render();

=head1 DESCRIPTION

Markdown template, for the daily needs.

=head1 METHODS

=head2 get_template()

Return a un-interpreted template string respecting the
L<Mojo::Template|https://docs.mojolicious.org/Mojo/Template> engine syntax.

=head2 render()

Interpolate the template with the provided data.

=cut
