package Imager::CommandLine::NewTemplate {
  use MooseX::App;
  use MooseX::Types::Path::Class;
  use Path::Class;
  use Cwd;
  use Template;
  use v5.10;

  option version => (
    is => 'ro',
    isa => 'Int',
    documentation => 'The version of the template type to use',
    lazy => 1,
    default => sub {
      my $self = shift;
      my $dir = dir ( $self->template_dir, $self->type );
      my @dirs = sort map { $_->basename } grep { $_->is_dir } $dir->children;
      pop @dirs;
    },
  );

  has template_dir => (
    is => 'ro',
    isa => 'Path::Class::Dir',
    lazy => 1,
    default => sub {
      dir ( $FindBin::Bin, '..', 'templates', 'ami' );
    }
  );

  has _template_base => (
    is => 'ro',
    isa => 'Path::Class::Dir',
    lazy => 1,
    default => sub {
      my $self = shift;
      # template_dir, template_type, template_
      dir ( $self->template_dir, $self->type, $self->version )
    }
  );

  has _files => (
    is => 'ro',
    lazy => 1,
    isa => 'ArrayRef[Path::Class::File]',
    traits => [ 'Array' ],
    handles => {
      files => 'elements',
    },
    default => sub {
      my $self = shift;
      my @files;
      while (my $file = $self->_template_base->next) {
        next unless -f $file;
        push @files, $file;
      }
      return \@files;
    }
  );

  option type => (
    is => 'ro',
    isa => 'Str',
    documentation => 'The template type to use',
    required => 1,
  );

  parameter name => (
    is => 'ro',
    isa => 'Str',
    documentation => 'The name for the AMI Class',
    required => 1,
  );

  has destination_dir => (
    is => 'ro',
    isa => 'Str',
    default => sub {
      my $self = shift;
      getcwd;
    }
  );

  has _name_for_path => (
    is => 'ro',
    isa => 'Path::Class::File',
    lazy => 1,
    default => sub {
      my $self = shift;
      my $file_name = $self->name;
      $file_name =~ s|::|/|g;
      file($file_name);
    }
  );

  has _template_engine => (
    is => 'ro',
    default => sub {
      Template->new(
        INTERPOLATE => 0,
        EVAL_PERL => 0,
      ) || die Template->error();
    }
  );

  sub run {
    my ($self) = @_;

    say "Spawning template for ", $self->type;
    foreach my $file ($self->files) {
      my $rebase_from = $self->_template_base;
      my $rebase_to = $self->destination_dir;
      my $file_path = $file->stringify;

      $file_path =~ s/^$rebase_from/$rebase_to/;
      $file_path =~ s/NAME/$self->_name_for_path/ge;

      $file_path = file($file_path);

      my $input = $file->slurp;
      my $output;
      $self->_template_engine->process(
        \$input,
        { name      => $self->name,
          name_path => $self->_name_for_path,
          type      => $self->type,
          version   => $self->version,
        },
        \$output
      );
      # Ensure the path exists
      $file_path->parent->mkpath;
      if (-e $file_path) {
        warn "Not overwritting $file_path";
      } else {
        $file_path->spew($output);
      }
    }
  }
}

1;
