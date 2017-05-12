#    Copyright (c) 2011 Raphaël Pinson.
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Model is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
#    02110-1301 USA

package Config::Augeas::Exporter;
use strict;
use warnings;
use base qw(Class::Accessor);

use Config::Augeas qw(get match count_match);
use XML::LibXML;
use Encode qw(encode);
use YAML qw(Dump);
use JSON qw();
use File::Path qw(mkpath);

__PACKAGE__->mk_accessors(qw(to_xml to_hash to_yaml to_json from_xml));

our $VERSION = '1.0.0';

# Default values
my $PATH = '/files';


=head1 NAME

Config::Augeas::Exporter - Export the Augeas tree to various formats

=head1 SYNOPSIS

  use Config::Augeas::Exporter

  # Initiliaze
  my $aug = Config::Augeas::Exporter->new( root => $aug_root );

  # Export to XML
  my $doc = $aug->to_xml( 
    path => ['/files/etc/fstab', '/files/etc/apt'],
    exclude => ['#comment', '#mcomment'],
    file_stat => 1,
    );

  print $doc->toString;

  # Restore from XML
  open (my $fh, "<$file") 
    or die "E: Could not open $file: $!\n" ;
  my $doc = XML::LibXML->load_xml(IO => $fh);
  close $fh;

  my $aug = Config::Augeas::Exporter->new(root => $root);
  $aug->from_xml(
     xml => $doc,
     create_dirs => 1,
     );


=head1 DESCRIPTION

This module allows to export the Augeas tree to various formats and import back from these formats to the configuration files.

=head1 Constructor

=head1 new ( ... )

Creates a new Config::Augeas::Exporter object. Optional parameters are:

=over

=item augeas

A Config::Augeas object. If not provided, a new one will be created.

=item root

Use C<root> as the filesystem root.

=back

=cut


sub new {
   my $class = shift;
   my %options = @_;

   my $root = $options{root};
   $root ||= '';

   $class = ref $class || $class || __PACKAGE__;
   my $self = __PACKAGE__->SUPER::new();

   # Initiliaze Augeas if it wasn't passed
   my $aug = $options{augeas};
   unless($aug) {
      $aug = Config::Augeas->new(root => $root);
   }

   # Associate to object
   $self->{aug} = $aug;

   # Get augeas root
   $self->{aug_root} = $aug->get('/augeas/root');

   return $self;
}


=head1 Methods

=head2 to_xml( ... )

Export the Augeas tree to a XML::LibXML::Document object.

=over

=item path

An array of Augeas paths to export. If ommitted, it will default to '/files'.

=item exclude

An array of label patterns to exclude from the export.

=item file_stat

A boolean, whether to include file stat.

=back

=cut


sub to_xml {
   my $self = shift;
   my %args = @_;

   my @paths = @{$args{path}} if $args{path};
   my @excludes = @{$args{exclude}} if $args{exclude};
   my $file_stat = $args{file_stat};

   # Defaults
   @paths = $PATH if ($#paths < 0);

   # Initialize XML document
   my $doc = XML::LibXML::Document->new('1.0', 'utf-8');

   # Get XML elements from augeas recursively
   my @file_elems;
   for my $path (@paths) {
      my @new_file_elems = (node_to_xml($self, $path, \@excludes, 1, $file_stat));
      map { push @file_elems, $_ } @new_file_elems;
   }

   # Add a files node for all file entries
   my $files = XML::LibXML::Element->new('files');
   map { $files->appendChild($_) } @file_elems;

   # Raise warning if no "file" node was found
   my @node_nodes = $files->findnodes("//node");
   my @file_nodes = $files->findnodes("//file");

   if ($#node_nodes >= 0 && $#file_nodes < 0) {
      warn "W: The XML export contains no file nodes.
W: You will not be able to import it back.\n";
   }

   # Add an error node for errors
   my @error_elems = (node_to_xml($self, '/augeas//error', [], 0, 0));
   my $errors = XML::LibXML::Element->new('error');
   map { $errors->appendChild($_) } @error_elems;

   # Add an augeas node on top
   my $augeas = XML::LibXML::Element->new('augeas');
   $augeas->appendChild($files);
   $augeas->appendChild($errors);

   # Associate files node with document
   $doc->setDocumentElement($augeas);

   return $doc;
}


sub node_to_xml {
   my ($self, $path, $excludes, $check_is_file, $incl_file_stat) = @_;

   # Default check is_file
   $check_is_file = 1 unless(defined($check_is_file));

   # Default incl_file_stat
   $incl_file_stat = 0 unless(defined($incl_file_stat));

   # Get label from path
   my $label = get_label($path);

   # Filter excludes
   return if exclude_match($label, $excludes);

   # Sanitize path for augeas requests
   $path = sanitize_path($path);

   my $aug = $self->{aug};
   my @children = $aug->match("$path/*");

   # Should children check is_file?
   my $children_check_is_file = $check_is_file;
   if ($check_is_file && is_file($self, $path)) {
      $children_check_is_file = 0;
   }

   # Parse children
   my @child_elems;
   for my $child (@children) {
      my @new_child_elems = (node_to_xml($self, $child, $excludes, $children_check_is_file, $incl_file_stat));
      map { push @child_elems, $_ } @new_child_elems;
   }

   # Directories don't get their own node
   return @child_elems if ($check_is_file && $self->is_dir($path));

   # Files and entries get their own nodes
   my $elem;
   if ($check_is_file && is_file($self, $path)) {
      # Files get <file path="$path"> nodes
      $elem = XML::LibXML::Element->new('file');
      my $file_path = get_file_path($path);
      $elem->setAttribute("path", $file_path);
      
      # Include file stat if requested
      if ($incl_file_stat) {
         my $file_stat = $self->stat_to_xml($file_path);
         $elem->appendChild($file_stat);
      }
   } else {
      # Entries get <node label="$label"> nodes
      $elem = XML::LibXML::Element->new('node');
      $elem->setAttribute("label", $label);
   }

   # Append children to element
   map { $elem->appendChild($_) } @child_elems;

   # Add value to element
   my $value = $aug->get($path);
   if (defined($value)) {
      my $value_elem = XML::LibXML::Element->new('value');
      $value_elem->appendTextNode(encode('utf-8', $value)) if defined($value);
      $elem->appendChild($value_elem);
   }

   return $elem;
}


=head2 to_hash( ... )

Export the Augeas tree to a hash.

=over

=item path

C<path> is the Augeas path to export. If ommitted, it will default to '/files'.

=item exclude

A list of label patterns to exclude from the export.

=back

=cut


sub to_hash {
   my $self = shift;
   my %args = @_;

   my $path = $args{path};
   my @excludes = ($args{exclude});

   # Default path
   $path ||= $PATH;

   my @file_elems = (node_to_hash($self, $path, \@excludes));

   my %hash = (
      files => \@file_elems,
      );

   return \%hash;
}


sub node_to_hash {
   my ($self, $path, $excludes) = @_;

   # Get label from path
   my $label = get_label($path);

   # Filter excludes
   return if exclude_match($label, $excludes);

   # Sanitize path for augeas requests
   $path = sanitize_path($path);

   my $aug = $self->{aug};
   my @children = $aug->match("$path/*");

   # Parse children
   my @child_elems;
   for my $child (@children) {
      my @new_child_elems = (node_to_hash($self, $child, $excludes));
      map { push @child_elems, $_ } @new_child_elems;
   }

   # Directories don't get their own node
   return @child_elems if ($self->is_dir($path));

   # Initialize array
   my %hash;
   my $node_hash;

   if (is_file($self, $path)) {
      my $file_path = get_file_path($path);
      $node_hash = \%{$hash{$file_path}};
   } else {
      $node_hash = \%{$hash{$label}};
   }

   # Append children
   map { push @{$node_hash->{children}}, $_ } @child_elems;

   # Add value to element
   my $value = $aug->get($path);
   $node_hash->{value} = $value if defined($value);

   return \%hash;
}


=head2 to_yaml( ... )

Export the Augeas tree to YAML.

=over

=item path

C<path> is the Augeas path to export. If ommitted, it will default to '/files'.

=item exclude

A list of label patterns to exclude from the export.

=back

=cut

sub to_yaml {
   my $self = shift;
   my %args = @_;

   my $hash = $self->to_hash(%args);

   return YAML::Dump($hash);
}


=head2 to_json( ... )

Export the Augeas tree to JSON.

=over

=item path

C<path> is the Augeas path to export. If ommitted, it will default to '/files'.

=item exclude

A list of label patterns to exclude from the export.

=back

=cut

sub to_json {
   my $self = shift;
   my %args = @_;

   my $hash = $self->to_hash(%args);

   my $json = new JSON;
   return $json->encode($hash);
}


=head2 from_xml( ... )

Restore the Augeas tree from an XML::LibXML::Document object.
This method considers the files listed in the XML document,
and replaces the corresponding files in the Augeas tree with
the contents of the XML.

=over

=item xml

The XML::LibXML::Document to use as source for import.

=item create_dirs

Boolean value, whether to create the directories if missing.

=back

=cut


sub from_xml {
   my $self = shift;
   my %args = @_;

   die "E: No XML provided." unless(defined($args{xml}));

   my $xml = $args{xml};
   my $create_dirs = $args{create_dirs};
   my $aug = $self->{aug};

   my @files = $xml->find('/augeas/files/file')->get_nodelist();

   if ($#files < 0) {
      warn "W: The XML document contains no file to restore.";
      return;
   }

   # Get augeas root to create directories
   my $aug_root = $self->{aug_root};
   die "E: Could not determine Augeas root needed to create directories."
      if ($create_dirs && !defined($aug_root));

   # Add each file to the Augeas tree
   for my $file (@files) {
      my $path = $file->getAttribute('path');

      # Create directories if requested
      if($create_dirs) {
         if ($path =~ m|^(.*)/([^/]+)$|) {
           my $dir = "${aug_root}${1}";
           unless (-d $dir) {
              mkpath($dir) or die "E: Failed to create directory $dir: $!";
           }
         } else {
            die "E: Could not get directory from file path $path.";
         }
      }

      my $aug_path = "/files${path}";
      # Clean the Augeas tree for this file
      $aug->rm($aug_path);

      for my $node ($file->childNodes) {
         $self->xml_to_node($node, $aug_path);
      }
   }

   $aug->save;
   $aug->print('/augeas//error');
}


sub xml_to_node {
   my ($self, $elem, $path) = @_;

   my $aug = $self->{aug};

   my $name = $elem->nodeName;
   my $label = $elem->getAttribute('label');

   # Ignore stat nodes
   return if ($name eq 'stat');

   my $matchpath = "$path/*[last()]";
   $matchpath = sanitize_path($matchpath);
   my $lastpath = sanitize_path($aug->match("$path/*[last()]"));

   if(defined($lastpath)) {
      # Insert last node
      $aug->insert($label, "after", $lastpath);
   } else {
      # Config::Augeas doesn't take undef
      #   as a correct value or provide clear
      # This is an ugly trick to do the same
      #   hoping the previous children did not
      #   create a ##foo node
      my $create_path = sanitize_path("$path/$label/#foo");
      $aug->set($create_path, "foo");
      $aug->rm($create_path);
   }

   $matchpath = sanitize_path("${path}/${label}[last()]");
   my $newpath = sanitize_path($aug->match($matchpath));

   my $value;

   for my $child ($elem->childNodes()) {
      if ($child->nodeName eq 'value') {
         # Text node
         $value = $child->textContent;
      } else {
         $self->xml_to_node($child, $newpath);
      }
   }

   if (defined($value)) {
      $aug->set($newpath, $value);
   }
}


##############
# Useful subs
##############

sub get_file_path {
   my ($path) = @_;

   my $file_path = $path;
   $file_path =~ s|^/files||;
   
   return $file_path;
}


sub get_label {
   my ($path) = @_;

   # Get label from path
   my $label = '';

   if ($path =~ m|.*/([^/\[]+)(\[\d+\])?|) {
      $label = $1;
   } else {
      die "E: Could not parse $path\n";
   }

   return $label;
}


sub exclude_match {
   my ($label, $excludes) = @_;

   # Filter excludes
   for my $exclude (@$excludes) {
      if ($exclude && $label =~ /$exclude/) {
         return 1;
      }
   }

   return 0;
}


sub sanitize_path {
   my ($path) = @_;

   return unless ($path);

   # Sanitize path for augeas requests
   $path =~ s|(?<=[^\\]) |\\ |g;

   return $path;
}


sub is_file {
   my ($self, $path) = @_;

   my $aug_path = "/augeas${path}/path";
   my $aug = $self->{aug};
   my $count = $aug->count_match($aug_path);

   # Not a file if there is no path subnode
   return 0 if ($count == 0);
   # Check that the subnode has the right value
   return 1 if ($aug->get($aug_path) eq $path);
   # Otherwise it's not a file
   return 0;
}


sub is_dir {
   my ($self, $path) = @_;

   my $aug_path = "/augeas${path}";
   my $aug = $self->{aug};
   my $count = $aug->count_match($aug_path);
   my $value = $aug->get($aug_path);

   # A directory is not a file
   # but its path must exist in /augeas
   # and have no value associated to it
   return 1 if (!$self->is_file($path) && $count == 1
                                       && !defined($value));
   # Otherwise it's not a directory
   return 0;
}


sub stat_to_xml {
   my ($self, $path) = @_;
   my $aug_root = $self->{aug_root};

   my %stat;
   ($stat{dev}, $stat{ino}, $stat{mode}, $stat{nlink},
    $stat{uid}, $stat{gid}, $stat{rdev}, $stat{size},
    $stat{atime}, $stat{mtime}, $stat{ctime},
    $stat{blksize}, $stat{blocks}) = stat("${aug_root}${path}");

   my $stat_elem = XML::LibXML::Element->new('stat');

   for my $k (keys(%stat)) {
      $stat_elem->setAttribute($k, $stat{$k});
   }

   return $stat_elem;
}


__END__


=head1 SEE ALSO

=over

=item *

L<Config::Augeas> : The Config::Augeas module

=item * 

http://augeas.net/ : The Augeas project page

=back

=head1 AUTHOR

RaphaE<euml>l Pinson, E<lt>raphink at cpan dot orgE<gt>

=head1 CONTRIBUTING

This module is developed on Launchpad at:

L<https://launchpad.net/config-augeas-exporter> 

Feel free to fork the repository and submit pull requests

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by RaphaE<euml>l Pinson

This library is free software; you can redistribute it and/or modify
it under the LGPL terms.

=cut


