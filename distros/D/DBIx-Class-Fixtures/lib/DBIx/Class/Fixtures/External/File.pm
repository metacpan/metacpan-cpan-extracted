package DBIx::Class::Fixtures::External::File;
$DBIx::Class::Fixtures::External::File::VERSION = '1.001039';
use strict;
use warnings;

use File::Spec::Functions 'catfile', 'splitpath';
use File::Path 'mkpath';

sub _load {
  my ($class, $path) = @_;
  open(my $fh, '<', $path)
    || die "can't open $path: $!";
  local $/ = undef;
  my $content = <$fh>;
}

sub _save {
  my ($class, $path, $content) = @_;
  open (my $fh, '>', $path)
    || die "can't open $path: $!";
  print $fh $content;
  close($fh);
}

sub backup {
  my ($class, $key, $args) = @_;
  my $path = catfile($args->{path}, $key);
  return $class->_load($path);
}

sub restore {
  my ($class, $key, $content, $args) = @_;
  my $path = catfile($args->{path}, $key);
  my ($vol, $directory, $file) = splitpath($path);
  mkpath($directory) unless -d $directory;
  $class->_save($path, $content);
}

1;

=head1 NAME

DBIx::Class::Fixtures::External::File - save and restore external data

=head1 SYNOPSIS

    my $fixtures = DBIx::Class::Fixtures
      ->new({
        config_dir => 't/var/configs',
        config_attrs => { photo_dir => './t/var/files' });

    {
        "sets": [{
            "class": "Photo",
            "quantity": "all",
            "external": {
                "file": {
                    "class": "File",
                    "args": {"path":"__ATTR(photo_dir)__"}
                }
            }
        }]
    }

=head1 DESCRIPTION

Sometimes your database fields are pointers to external data.  The classic
example is you are using L<DBIx::Class::InflateColumn::FS> to manage blob
data.  In these cases it may be desirable to backup and restore the external
data via fixtures.

This module performs this function and can also serve as an example for your
possible custom needs.

=head1 METHODS

This module defines the following methods

=head2 backup

Accepts: Value of Database Field, $args

Given the value of a database field (which is some sort of pointer to the location
of an actual file, and a hashref of args (passed in the args key of your config
set), slurp up the file and return to to be saved in the fixure.

=head2 restore

Accepts: Value of Database Field, Content, $args

Given the value of a database field, some blob content and $args, restore the
file to the filesystem

=head1 AUTHOR

    See L<DBIx::Class::Fixtures> for author information.

=head1 CONTRIBUTORS

    See L<DBIx::Class::Fixtures> for contributor information.

=head1 LICENSE

    See L<DBIx::Class::Fixtures> for license information.

=cut

