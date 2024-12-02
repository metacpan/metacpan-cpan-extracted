package App::Standup::Diary;

use v5.28;

use Config::Tiny;
use Object::Pad;
use Path::Tiny;

use App::Standup::Role::Project;
use App::Standup::Role::Date;
use App::Standup::Diary::Template;

our $VERSION = '0.08';

class App::Standup::Diary :does( Date ) :does( Project ) {

  no warnings 'experimental';

  field $config :accessor :param { Config::Tiny->read('diary.conf') };

  field $daily_data_path :accessor;

  field $data_dir :param :reader;

  field $template :writer :accessor;

  method init_daily_data_path ($path) {
    $daily_data_path = $data_dir ?
      path( $data_dir . '/' . $path ) :
      path( $config->{data}->{path} . '/' . $path );
  }

  method write {

    $self->set_template( App::Standup::Diary::Template->new(
      date         => $self->date,
      project_name => $self->project_name
    ));

    if ( $self->should_create_dir ) {
      say "$daily_data_path should be created";
      $self->create_directories_tree;
    } else {
      $self->init_daily_data_path($self->build_path($self->date->ymd('/')));
    }

    my $file_path = path($self->build_full_file_path);

    path($file_path)->spew_utf8($template->render) and say "Diary entry created $file_path"
      unless $file_path->exists and say "Entry already exist";

  }

  # TODO should have a App::Standup::Diary::Path object for those
  method build_full_file_path {
    return $daily_data_path .
      '/' .
      $self->date->ymd .
      '_' .
      lc $self->project_name .
      '.md';
  }

  method build_path ($date) {
    my ($path) = $date =~ m/ \d{4} \/ \d{2} /gx ;
    return $path;
  }

  method should_create_dir {
    $self->init_daily_data_path($self->build_path($self->date->ymd('/')));
    return $daily_data_path->exists ? 0 : 1;
  }

  method create_directories_tree {

    # Unimplemented, see #29
    if ($self->date->day_of_month == 1 ) {
      # TODO if first day of the month
      # Create a Priorities file
    }

    my @created = $daily_data_path->mkpath;
    say "Created $daily_data_path" if @created;
  }
}

=encoding utf8

=head1 NAME

App::Standup::Diary - Manage a simple Markdown journal for your daily standups

=head1 SYNOPSIS

  # From command line
  diary --data-dir /home/smonff/diary/ --project-name SeriousWork

  # In your Perl code
  my $diary = App::Standup::Diary
    ->new(
      data_dir     => $data_dir,
      project_name => $project_name
  );

  $diary->write();


=head1 DESCRIPTION

This module is the implementation of the L<diary> command, that can help to keep
a directory of organized daily notes aimed at standup preparation and
presentation.

It provides a couple of ways to customize the notes template.

It use internal tools built with CPAN modules:

=over 2

=item L<App::Standup::Diary::Template>

The Markdown template where your data are interpolated.

=item L<Standup::Role::Date>

Provide date features for all the C<diary> uses.

=item L<Standup::Role::Project>

Provide a project name, so far.

=back

=head1 MOTIVATIONS

Daily standups are a common, tried and tested modern work methodology. They are
I<"brief, daily collaboration meeting in which the team review progress from the
previous day, declares intentions for the current day, and highlights any
obstacles encountered or anticipated"> (L<source|brief, daily collaboration
meeting in which the team review progress from the previous day, declares
intentions for the current day, and highlights any obstacles encountered or
anticipated.>).

This tool is supposed to provide self-support for persons:

=over 2

=item Who struggle with daily standups presentations oral expression

=item Surely familiar with the Perl ecosystem

=back

=head2 How did it start?

Social anxiety can make my standup presentation very confusing. I also tend to
forget key points if improvising, due to the stress of having no talk notes
support. Keeping a diary of my thoughts drastically helped me to stay calm and
collaborate better with the various teams I worked with. And if they are well
sorted by year, month and day, it makes very easy to find old notes for eventual
later usage.

=head2 Ready for production

I have been using it at work since 2021 and it helped me to reduce the stress of
standups and meeting.

=head2 Methodology

Every morning, create the daily file by running C<diary>. It's template is a
simple 3 items list. Open the day file in C<$data_dir/$year/$month/> and stash
your thoughts by using the following methodology:

=over 2

=item C<done>

List of tasks you accomplished in the previous day

=item C<todo>

List of tasks you plan to accomplish today

=item C<blockers>

List of eventual blockers, so that your colleagues can support you

=back

Then just read the notes during the daily standup.

=head2 Experiment with Object::Pad

L<App::Standup::Diary> is my pet project for Perl's Corinna implementation of the
core OOP features. C<diary> use L<Object::Pad>, not the C<class> feature
introduced in Perl C<5.40>. L<Object::Pad> is the test bed for the new core OO
system.

=head1 INSTALLATION

=head2 For common usage

    cpanm App::Standup::Diary

It will make the C<diary> command available in the C<~/perl5/bin/> directory.
Should be available in your C<PATH>.

See L<diary> for command line usage.

=head2 For development

  # Install a Perl module manager
  apt install carton

  git clone git@codeberg.org:smonff/Diary.git

  cd Diary

  # Install CPAN dependencies
  carton install

=head1 How to use it?

I set an alias in my C<.bashrc>. Should also work in your own-favorite-shell:

  alias diary="diary --data-dir /home/smonff/diary --project-name SeriousWork";

Each morning, before my work standup, I run C<diary>. It create a Markdown file
in the specified C<--project-name> directory. I then edit my thoughts with an
editor.

See L<diary> for command line usage.

=head1 FIELDS

=head2 config

=head2 daily_data_path

=head2 data_dir

=head2 template

A L<App::Standup::Diary::Template> object.

=head1 METHODS

=head2 build_full_file_path()

=head2 build_path($self->date->ymd('/'))

Use the date from C<Standup::Role::Date> to build the final path file name.

=head2 create_directories_tree()

If C<$self->should_create_dir()> returns a true value, it would take care of the
directory creation using L<Path::Tiny> C<mkpath>.

=head2 init_daily_data_path($file_path)

Helper that initialize C<$daily_data_path> with a C<Path::Tiny> instance
for the current day diary entry.

  # foo/2022/03 (Path::Tiny)
  $self->init_daily_data_path($self->build_path)

=head2 should_create_dir()

Check if a new I<year> or I<month> directory should be created so that we can
store the standup file. In simpler words: are we the first day of the year, or
of the month?

=head2 write()

This is C<App::Standup::Diary> entry point, AKA C<main()>.

=head1 TODOs

=over 2

=item Make the template configurable by setting it in a separate file

=item Retrieve TODOS from previous days

=back

See the L<issues tracker|https://codeberg.org/smonff/Standup-Diary/issues>.

=head1 SEE ALSO

A couple of similar tools:

=over 2

=item L<StandupGenerator|https://metacpan.org/release/JTREEVES/StandupGenerator-0.5/source/README.md>

On the CPAN, this is pretty much all what I found. I like the spirit of this
one.

=item L<Almanac|https://codeberg.org/jameschip/almanac>

A similar effort written in Bash.

=back

=head1 ACKNOWLEDGEMENTS

Thanks to the maintainers of L<Config::Tiny>, L<Mojo::Template>, L<Object::Pad>,
L<Path::Tiny>, L<Time::Piece>.

=head1 LICENSE

Copyright 2022-2024 Sebastien Feugère

This library is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.

See L<perlartistic>.

=head1 AUTHOR

Sébastien Feugère - seb@feugere.net

=cut
