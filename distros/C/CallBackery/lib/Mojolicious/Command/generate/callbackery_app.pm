package Mojolicious::Command::generate::callbackery_app;
use Mojo::Base 'Mojolicious::Command';
use File::Basename;
use Mojo::Util qw(class_to_file class_to_path);
use Mojo::File;

use POSIX qw(strftime);
use Cwd 'getcwd';
use File::Spec::Functions qw(catdir catfile);

has description => 'Generate CallBackery web application directory structure.';
has usage => sub { shift->extract_usage };

has cwd => sub {
    getcwd();
};

sub rel_dir  {
    my $self=shift;
    catdir $self->cwd,  split('/', pop)
}

sub rel_file {
    my $self =shift;
    catfile $self->cwd, split('/', pop);
}

sub run {
    my ($self, $app) = @_;
    $app ||= 'MyCallBackeryApp';
    my @dir = split /\//, $app;
    my $class = pop @dir;

    die <<EOF unless $class =~ /^[A-Z](?:\w|::)+$/;
Your application name has to be a well formed (CamelCase) Perl module name
like "MyApp".
EOF
    $self->cwd(join '/', @dir) if @dir;

    my $name = class_to_file $class;
    my $qxclass = $name;
    $name =~ s/_/-/g;
    my $class_path = class_to_path $class;
    # Configure Main Dir
    my $file = {
        'configure.ac' => 'configure.ac',
        'bootstrap' => 'bootstrap',
        'PERL_MODULES' => 'PERL_MODULES',
        'VERSION' => 'VERSION',
        'README' => 'README',
        'AUTHORS' => 'AUTHORS',
        '.gitignore' => '.gitignore',
        'LICENSE' => 'LICENSE',
        'COPYRIGHT' => 'COPYRIGHT',
        'CHANGES' => 'CHANGES',
        'Makefile.am' => 'Makefile.am',
        'bin/Makefile.am' => 'bin/Makefile.am',
        'thirdparty/Makefile.am' => 'thirdparty/Makefile.am',
        'etc/Makefile.am' => 'etc/Makefile.am',
        'etc/app.cfg' => 'etc/'.$name.'.cfg',
        'bin/script.pl' => 'bin/'.$name.'.pl',
        'bin/source-mode.sh' => 'bin/'.$name.'-source-mode.sh',
        'lib/App.pm' => 'lib/'.$class_path,
        'lib/Makefile.am' => 'lib/Makefile.am',
        'lib/App/GuiPlugin/Song.pm' => 'lib/'.$class.'/GuiPlugin/Song.pm',
        'lib/App/GuiPlugin/SongForm.pm' => 'lib/'.$class.'/GuiPlugin/SongForm.pm',
        'frontend/Makefile.am' => 'frontend/Makefile.am',
        'frontend/Manifest.json' => 'frontend/Manifest.json',
        'frontend/config.json' => 'frontend/config.json',
        'frontend/source/class/app/Application.js' => 'frontend/source/class/'.$qxclass.'/Application.js',
        'frontend/source/class/app/__init__.js' => 'frontend/source/class/'.$qxclass.'/__init__.js',
        'frontend/source/class/app/theme/Theme.js' => 'frontend/source/class/'.$qxclass.'/theme/Theme.js',
        'frontend/source/index.html' => 'frontend/source/index.html',
        't/basic.t' => 't/basic.t',
    };

    my ($userName,$fullName) = (getpwuid $<)[0,6];
    $fullName =~ s/,.+//g;
    chomp(my $domain = `hostname -d`);
    my $email = $userName.'@'.$domain;

    if ( -r $ENV{HOME} . '/.gitconfig' ){
        my $in = Mojo::File->new($ENV{HOME} . '/.gitconfig')->slurp;
        $in =~ /name\s*=\s*(\S.+\S)/ and $fullName = $1;
        $in =~ /email\s*=\s*(\S+)/ and $email = $1;
    }
    

    for my $key (keys %$file){
        $self->render_to_rel_file($key, $name.'/'.$file->{$key}, {
            class => $class,
            name => $name,
            qxclass => $qxclass,
            class_path => $class_path,
            year => (localtime time)[5]+1900,
            email => $email,
            fullName => $fullName,
            userName => $userName,
            date => strftime('%Y-%m-%d',localtime(time)),
        });
    }

    $self->chmod_rel_file("$name/bootstrap", 0755);
    $self->chmod_rel_file("$name/bin/".$name.".pl", 0755);
    $self->chmod_rel_file("$name/bin/".$name."-source-mode.sh", 0755);

    $self->create_rel_dir("$name/public");
    $self->create_rel_dir("$name/templates");
    $self->create_rel_dir("$name/frontend/source/resource/$name");
    $self->create_rel_dir("$name/frontend/source/translation");
    chdir $self->cwd.'/'.$name;
    system "./bootstrap";

    say "** Generated App $class in ".$self->cwd.'/'.$name;

}

sub render_data {
  my ($self, $name) = (shift, shift);
    Mojo::Template->new->name("template $name")
    ->render(Mojo::File->new(dirname($INC{'Mojolicious/Command/generate/callbackery_app.pm'}).'/callbackery_app/'.$name)->slurp, @_);
}
1;

=encoding utf8

=head1 NAME

Mojolicious::Command::generate::callbackery_app - Calbackery App generator command

=head1 SYNOPSIS

  Usage: mojo generate callbackery_app [OPTIONS] [NAME]

    mojo generate callbackery_app
    mojo generate callbackery_app [/full/path/]TestApp

  Options:
    -h, --help   Show this summary of available options

=head1 DESCRIPTION

L<Mojolicious::Command::generate::callbackery_app> generates application directory
structures for fully functional L<CallBackery> applications.

=head1 ATTRIBUTES

L<Mojolicious::Command::generate::callbackery_app> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $app->description;
  $app            = $app->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $app->usage;
  $app      = $app->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::generate::callbackery_app> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $app->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<CallBackery>, L<http://callbackery.org>.

=cut
