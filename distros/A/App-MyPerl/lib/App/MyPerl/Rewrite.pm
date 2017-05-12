package App::MyPerl::Rewrite;

use Moo;
use IO::All;

with 'App::MyPerl::Role::Script';

sub use_files { qw(modules) }

has exclude_dev_preamble => (is => 'lazy', builder => sub {
  join "\n", '# App::MyPerl preamble', @{$_[0]->preamble},
});

has exclude_dev_script_preamble => (is => 'lazy', builder => sub {
  join "\n",
    '# App::MyPerl script preamble',
    @{$_[0]->_preamble_from_modules(@{$_[0]->script_modules})};
});

sub run {
  die "myperl-rewrite dir1 dir2 ..." unless @ARGV;
  $_[0]->rewrite_dir($_) for @ARGV;
}

sub rewrite_dir {
  my ($self, $dir) = @_;
  if ($self->_env_value('DEBUG')) {
    warn $self->exclude_dev_script_preamble."\n";
    warn $self->exclude_dev_preamble."\n";
  }
  my @files = grep $_->name =~ /\.pm$|\.t$|^${dir}\/bin\//,
                     io->dir($dir)->all_files(0);
  foreach my $file (@files) {
    my $data = $file->all;
    $file->print($self->rewritten_contents($data));
  }
}

sub rewritten_contents {
  my ($self, $data) = @_;
  my ($shebang, $line) = do {
    if ($data =~ s/\A(#!.*\n)//) {
      ($1.$self->exclude_dev_script_preamble."\n", 2)
    } else {
      ('', 1)
    }
  };
  return $shebang.$self->exclude_dev_preamble."\n#line ${line}\n".$data;
}

1;
