# Apache::ConfigParser: Load Apache configuration file.
#
# Copyright (C) 2001-2005 Blair Zajac.  All rights reserved.

package Apache::ConfigParser;

require 5.004_05;

use strict;

=head1 NAME

Apache::ConfigParser - Load Apache configuration files

=head1 SYNOPSIS

  use Apache::ConfigParser;

  # Create a new empty parser.
  my $c1 = Apache::ConfigParser->new;

  # Load an Apache configuration file.
  my $rc = $c1->parse_file('/etc/httpd/conf/httpd.conf');

  # If there is an error in parsing the configuration file, then $rc
  # will be false and an error string will be available.
  if (not $rc) {
    print $c1->errstr, "\n";
  }

  # Get the root of a tree that represents the configuration file.
  # This is an Apache::ConfigParser::Directive object.
  my $root = $c1->root;

  # Get all of the directives and starting of context's.
  my @directives = $root->daughters;

  # Get the first directive's name.
  my $d_name = $directives[0]->name;

  # This directive appeared in this file, which may be in an Include'd
  # or IncludeOptional'd file.
  my $d_filename = $directives[0]->filename;

  # And it begins on this line number.
  my $d_line_number = $directives[0]->line_number;

  # Find all the CustomLog entries, regardless of context.
  my @custom_logs = $c1->find_down_directive_names('CustomLog');

  # Get the first CustomLog.
  my $custom_log = $custom_logs[0];

  # Get the value in string form.
  $custom_log_args = $custom_log->value;

  # Get the value in array form already split.
  my @custom_log_args = $custom_log->get_value_array;

  # Get the same array but a reference to it.
  my $customer_log_args = $custom_log->value_array_ref;

  # The first value in a CustomLog is the filename of the log.
  my $custom_log_file = $custom_log_args->[0];

  # Get the original value before the path has been made absolute.
  @custom_log_args   = $custom_log->get_orig_value_array;
  $customer_log_file = $custom_log_args[0];

  # Here is a more complete example to load an httpd.conf file and add
  # a new VirtualHost directive to it.
  #
  # The Apache::ConfigParser object contains a reference to a
  # Apache::ConfigParser::Directive object, which can be obtained by
  # using Apache::ConfigParser->root.  The root node is a
  # Apache::ConfigParser::Directive which ISA Tree::DAG_Node (that is
  # Apache::ConfigParser::Directive's @ISA contains Tree::DAG_Node).
  # So to get the root node and add a new directive to it, it could be
  # done like this:

  my $c                = Apache::ConfigParser->new;
  my $rc               = $c->parse_file('/etc/httpd.conf');
  my $root             = $c->root;
  my $new_virtual_host = $root->new_daughter;
  $new_virtual_host->name('VirtualHost');
  $new_virtual_host->value('*');

  # The VirtualHost is called a "context" that contains other
  # Apache::ConfigParser::Directive's:

  my $server_name = $new_virtual_host->new_daughter;
  $server_name->name('ServerName');
  $server_name->value('my.hostname.com');

=head1 DESCRIPTION

The C<Apache::ConfigParser> module is used to load an Apache
configuration file to allow programs to determine Apache's
configuration directives and contexts.  The resulting object contains
a tree based structure using the C<Apache::ConfigParser::Directive>
class, which is a subclass of C<Tree::DAG_node>, so all of the methods
that enable tree based searches and modifications from
C<Tree::DAG_Node> are also available.  The tree structure is used to
represent the ability to nest sections, such as <VirtualHost>,
<Directory>, etc.

Apache does a great job of checking Apache configuration files for
errors and this modules leaves most of that to Apache.  This module
does minimal configuration file checking.  The module currently checks
for:

=over 4

=item Start and end context names match

The module checks if the start and end context names match.  If the
end context name does not match the start context name, then it is
ignored.  The module does not even check if the configuration contexts
have valid names.

=back

=head1 PARSING

Notes regarding parsing of configuration files.

Line continuation is treated exactly as Apache 1.3.20.  Line
continuation occurs only when the line ends in [^\\]\\\r?\n.  If the
line ends in two \'s, then it will replace the two \'s with one \ and
not continue the line.

=cut

use Exporter;
use Carp;
use Symbol;
use File::FnMatch                   0.01 qw(fnmatch);
use File::Spec                      0.82;
use Apache::ConfigParser::Directive      qw(DEV_NULL
                                            %directive_value_path_element_pos);

use vars qw(@ISA $VERSION);
@ISA     = qw(Exporter);
$VERSION = '1.02';

# This constant is used throughout the module.
my $INCORRECT_NUMBER_OF_ARGS = "passed incorrect number of arguments.\n";

# Determine if the filenames are case sensitive.
use constant CASE_SENSITIVE_PATH => (! File::Spec->case_tolerant);

=head1 METHODS

The following methods are available:

=over 4

=item $c = Apache::ConfigParser->new

=item $c = Apache::ConfigParser->new({options})

Create a new C<Apache::ConfigParser> object that stores the content of
an Apache configuration file.  The first optional argument is a
reference to a hash that contains options to new.

The currently recognized options are:

=over 4

=item pre_transform_path_sub => sub { }

=item pre_transform_path_sub => [sub { }, @args]

This allows the file or directory name for any directive that takes
either a filename or directory name to be transformed by an arbitrary
subroutine before it is made absolute with ServerRoot.  This
transformation is applied to any of the directives that appear in
C<%Apache::ConfigParser::Directive::directive_value_takes_path> that
have a filename or directory value instead of a pipe or syslog value,
i.e. "| cronolog" or "syslog:warning".

If the second form of C<pre_transform_path_sub> is used with an array
reference, then the first element of the array reference must be a
subroutine reference followed by zero or more arbitrary arguments.
Any array elements following the subroutine reference are passed to
the specified subroutine.

The subroutine is passed the following arguments:

  Apache::ConfigParser object
  lowercase string of the configuration directive
  the file or directory name to transform
  @args

NOTE: Be careful, because this subroutine will be applied to
ServerRoot and DocumentRoot, among other directives.  See
L<Apache::ConfigParser::Directive> for the complete list of directives
that C<pre_transform_path_sub> is applied to.  If you do not want the
transformation applied to any specific directives, make sure to check
the directive name and if you do not want to modify the filename,
return the subroutine's third argument.

If the subroutine returns an undefined value or a value with 0 length,
then it is replaced with C<< File::Spec->devnull >> which is the
appropriate 0 length file for the operating system.  This is done to
keep a value in the directive name since otherwise the directive may
not work properly.  For example, with the input

  CustomLog logs/access_log combined

and if C<pre_transform_path_sub> were to replace 'logs/access_log'
with '', then

  CustomLog combined

would no longer be a valid directive.  Instead,

  CustomLog C<File::Spec->devnull> combined

would be appropriate for all systems.

=item post_transform_path_sub => sub { }

=item post_transform_path_sub => [sub { }, @args]

This allows the file or directory name for any directive that takes
either a filename or directory name to be transformed by this
subroutine after it is made absolute with ServerRoot.  This
transformation is applied to any of the directives that appear in
C<%Apache::ConfigParser::Directive::directive_value_takes_path> that
have a filename or directory value instead of a pipe or syslog value,
i.e. "| cronolog" or "syslog:warning".

If the second form of C<post_transform_path_sub> is used with an array
reference, then the first element of the array reference must be a
subroutine reference followed by zero or more arbitrary arguments.
Any array elements following the subroutine reference are passed to
the specified subroutine.

The subroutine is passed the following arguments:

  Apache::ConfigParser object
  lowercase version of the configuration directive
  the file or directory name to transform
  @args

NOTE: Be careful, because this subroutine will be applied to
ServerRoot and DocumentRoot, among other directives.  See
L<Apache::ConfigParser::Directive> for the complete list of directives
that C<post_transform_path_sub> is applied to.  If you do not want the
transformation applied to any specific directives, make sure to check
the directive name and if you do not want to modify the filename,
return the subroutine's third argument.

If the subroutine returns an undefined value or a value with 0 length,
then it is replaced with C<< File::Spec->devnull >> which is the
appropriate 0 length file for the operating system.  This is done to
keep a value in the directive name since otherwise the directive may
not work properly.  For example, with the input

  CustomLog logs/access_log combined

and if C<post_transform_path_sub> were to replace 'logs/access_log'
with '', then

  CustomLog combined

would no longer be a valid directive.  Instead,

  CustomLog C<File::Spec->devnull> combined

would be appropriate for all systems.

=back

One example of where the transformations is useful is when the Apache
configuration directory on one host is NFS exported to another host
and the remote host parses the configuration file using
C<Apache::ConfigParser> and the paths to the access logs must be
transformed so that the remote host can properly find them.

=cut

sub new {
  unless (@_ < 3) {
    confess "$0: Apache::ConfigParser::new $INCORRECT_NUMBER_OF_ARGS";
  }

  my $class = shift;
  $class    = ref($class) || $class;

  # This is the root of the tree that holds all of the directives and
  # contexts in the Apache configuration file.  Also keep track of the
  # current node in the tree so that when options are parsed the code
  # knows the context to insert them.
  my $root = Apache::ConfigParser::Directive->new;
  $root->name('root');

  my $self = bless {
    current_node            => $root,
    root                    => $root,
    server_root             => '',
    post_transform_path_sub => '',
    pre_transform_path_sub  => '',
    errstr                  => '',
  }, $class;

  return $self unless @_;

  my $options = shift;
  unless (defined $options and UNIVERSAL::isa($options, 'HASH')) {
    confess "$0: Apache::ConfigParser::new not passed a HASH reference as ",
            "its first argument.\n";
  }

  foreach my $opt_name (qw(pre_transform_path_sub post_transform_path_sub)) {
    if (my $opt_value = $options->{$opt_name}) {
      if (UNIVERSAL::isa($opt_value, 'CODE')) {
        $self->{$opt_name} = [$opt_value];
      } elsif (UNIVERSAL::isa($opt_value, 'ARRAY')) {
        if (@$opt_value and UNIVERSAL::isa($opt_value->[0], 'CODE')) {
          $self->{$opt_name} = $opt_value;
        } else {
          confess "$0: Apache::ConfigParser::new passed an ARRAY reference ",
                  "whose first element is not a CODE ref for '$opt_name'.\n";
        }
      } else {
        warn "$0: Apache::ConfigParser::new not passed an ARRAY or CODE ",
             "reference for '$opt_name'.\n";
      }
    }
  }

  return $self;
}

=item $c->DESTROY

There is an explicit DESTROY method for this class to destroy the
tree, since it has cyclical references.

=cut

sub DESTROY {
  $_[0]->{root}->delete_tree;
}

# Apache 1.3.27 and 2.0.41 check if the AccessConfig, Include or
# ResourceConfig directives' value contains a glob.  Duplicate the
# exact same check here.
sub path_has_apache_style_glob {
  unless (@_ == 1) {
    confess "$0: Apache::ConfigParser::path_has_apache_style_glob ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  my $path = shift;

  # Apache 2.0.53 skips any \ protected characters in the path and
  # then tests if the path is a glob by looking for ? or * characters
  # or a [ ] pair.
  $path =~ s/\\.//g;

  return $path =~ /[?*]/ || $path =~ /\[.*\]/;
}

# Handle the AccessConfig, Include, IncludeOptional or ResourceConfig
# directives.  Support the Apache 1.3.13 behavior where if the path is
# a directory then Apache will recursively load all of the files in
# that directory.  Support the Apache 1.3.27 and 2.0.41 behavior where
# if the path contains any glob characters, then load the files and
# directories recursively that match the glob.
sub _handle_include_directive {
  unless (@_ == 5) {
    confess "$0: Apache::ConfigParser::_handle_include_directive ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  my ($self, $file_or_dir_name, $line_number, $directive, $path) = @_;

  # Apache 2.0.53 tests if the path is a glob and does a glob search
  # if it is.  Otherwise, it treats the path as a file or directory
  # and opens it directly.
  my @paths;
  if (path_has_apache_style_glob($path)) {
    # Apache splits the path into the dirname and basename portions
    # and then checks that the dirname is not a glob and the basename
    # is.  It then matches the files in the dirname against the glob
    # in the basename and generates a list from that.  Duplicate this
    # code here.
    my ($dirname,
        $separator,
        $basename) = $path =~ m#(.*)([/\\])+([^\2]*)$#;
    unless (defined $separator and length $separator) {
      $self->{errstr} = "'$file_or_dir_name' line $line_number " .
                        "'$directive $path': cannot split path into " .
                        "dirname and basename";
      return;
    }
    if (path_has_apache_style_glob($dirname)) {
      $self->{errstr} = "'$file_or_dir_name' line $line_number " .
                        "'$directive $path': dirname '$dirname' is a glob";
      return;
    }
    unless (path_has_apache_style_glob($basename)) {
      $self->{errstr} = "'$file_or_dir_name' line $line_number " .
                        "'$directive $path': basename '$basename' is " .
                        "not a glob";
      return;
    }
    unless (opendir(DIR, $dirname)) {
      $self->{errstr} = "'$file_or_dir_name' line $line_number " .
                        "'$directive $path': opendir '$dirname' " .
                        "failed: $!";
      # Check if missing file or directory errors should be ignored.
      # This checks an undocumented object variable which is normally
      # only used by the test suite to test the normal aspects of all
      # the directives without worrying about a missing file or
      # directory halting the tests early.
      if ($self->{_include_file_ignore_missing_file}) {
        # If the directory cannot be opened, then there are no
        # configuration files that could be opened for the directive,
        # so leave the method now, but with a successful return code.
        return 1;
      } else {
        return;
      }
    }

    # The glob code Apache uses is fnmatch(3).
    foreach my $n (sort readdir(DIR)) {
      next if $n eq '.';
      next if $n eq '..';
      if (fnmatch($basename, $n)) {
        push(@paths, "$dirname/$n");
      }
    }
    unless (closedir(DIR)) {
      $self->{errstr} = "'$file_or_dir_name' line $line_number " .
                        "'$directive $path': closedir '$dirname' " .
                        "failed: $!";
      return;
    }
  } else {
    @paths = ($path);
  }

  foreach my $p (@paths) {
    my @stat = stat($p);
    unless (@stat) {
      $self->{errstr} = "'$file_or_dir_name' line $line_number " .
                        "'$directive $path': stat of '$path' failed: $!";
      # Check if missing file or directory errors should be ignored.
      # This checks an undocumented object variable which is normally
      # only used by the test suite to test the normal aspects of all
      # the directives without worrying about a missing file or
      # directory halting the tests early.
      if ($self->{_include_file_ignore_missing_file}) {
        next;
      } else {
        return;
      }
    }

    # Parse this if it is a directory or points to a file.
    if (-d _ or -f _) {
      unless ($self->parse_file($p)) {
        return;
      }
    } else {
      $self->{errstr} = "'$file_or_dir_name' line $line_number " .
                        "'$directive $path': cannot open non-file and " .
                        "non-directory '$p'";
      return;
    }
  }

  return 1;
}

=item $c->parse_file($filename)

This method takes a filename and adds it to the already loaded
configuration file inside the object.  If a previous Apache
configuration file was loaded either with new or parse_file and the
configuration file did not close all of its contexts, such as
<VirtualHost>, then the new configuration directives and contexts in
C<$filename> will be added to the existing context.

If there is a failure in parsing any portion of the configuration
file, then this method returns undef and C<< $c->errstr >> will contain a
string explaining the error.

=cut

sub parse_file {
  unless (@_ == 2) {
    confess "$0: Apache::ConfigParser::parse_file $INCORRECT_NUMBER_OF_ARGS";
  }

  my ($self, $file_or_dir_name) = @_;

  my @stat = stat($file_or_dir_name);
  unless (@stat) {
    $self->{errstr} = "cannot stat '$file_or_dir_name': $!";
    return;
  }

  # If this is a real directory, than descend into it now.
  if (-d _) {
    unless (opendir(DIR, $file_or_dir_name)) {
      $self->{errstr} = "cannot opendir '$file_or_dir_name': $!";
      return;
    }
    my @entries = sort grep { $_ !~ /^\.{1,2}$/ } readdir(DIR);
    unless (closedir(DIR)) {
      $self->{errstr} = "closedir '$file_or_dir_name' failed: $!";
      return;
    }

    my $ok = 1;
    foreach my $entry (@entries) {
      $ok = $self->parse_file("$file_or_dir_name/$entry") && $ok;
      next;
    }

    if ($ok) {
      return $self;
    } else {
      return;
    }
  }

  # Create a new file handle to open this file and open it.
  my $fd = gensym;
  unless (open($fd, $file_or_dir_name)) {
    $self->{errstr} = "cannot open '$file_or_dir_name' for reading: $!";
    return;
  }

  # Change the mode to binary to mode to handle the line continuation
  # match [^\\]\\[\r]\n.  Since binary files may be copied from
  # Windows to Unix, look for this exact match instead of relying upon
  # the operating system to convert \r\n to \n.
  binmode($fd);

  # This holds the contents of any previous lines that are continued
  # using \ at the end of the line.  Also keep track of the line
  # number starting a continued line for warnings.
  my $continued_line = '';
  my $line_number    = undef;

  # Scan the configuration file.  Use the file format specified at
  #
  # http://httpd.apache.org/docs/configuring.html#syntax
  #
  # In addition, use the semantics from the function ap_cfg_getline
  # in util.c
  # 1) Leading whitespace is first skipped.
  # 2) Configuration files are then parsed for line continuation.  The
  #    line continuation is [^\\]\\[\r]\n.
  # 3) If a line continues onto the next line then the line is not
  #    scanned for comments, the comment becomes part of the
  #    continuation.
  # 4) Leading and trailing whitespace is compressed to a single
  #    space, but internal space is preserved.
  while (<$fd>) {
    # Apache is not consistent in removing leading whitespace
    # depending upon the particular method in getting characters from
    # the configuration file.  Remove all leading whitespace.
    s/^\s+//;

    next unless length $_;

    # Handle line continuation.  In the case where there is only one \
    # character followed by the end of line character(s), then the \
    # needs to be removed.  In the case where there are two \
    # characters followed by the end of line character(s), then the
    # two \'s need to be replaced by one.
    if (s#(\\)?\\\r?\n$##) {
      if ($1)  {
        $_ .= $1;
      } else {
        # The line is being continued.  If this is the first line to
        # be continued, then note the starting line number.
        unless (length $continued_line) {
          $line_number = $.;
        }
        $continued_line .= $_;
        next;
      }
    } else {
      # Remove the end of line characters.
      s#\r?\n$##;
    }

    # Concatenate the continuation lines with this line.  Only update
    # the line number if the lines are not continued.
    if (length $continued_line) {
      $_              = "$continued_line $_";
      $continued_line = '';
    } else {
      $line_number    = $.;
    }

    # Collapse any ending whitespace to a single space.
    s#\s+$# #;

    # If the line begins with a #, then skip the line.
    if (substr($_, 0, 1) eq '#') {
      next;
    }

    # If there is nothing on the line, then skip it.
    next unless length $_;

    # If the line begins with </, then it is ending a context.
    if (my ($context) = $_ =~ m#^<\s*/\s*([^\s>]+)\s*>\s*$#) {
      # Check if an end context was seen with no start context in the
      # configuration file.
      my $mother = $self->{current_node}->mother;
      unless (defined $mother) {
        $self->{errstr} = "'$file_or_dir_name' line $line_number closes " .
                          "context '$context' which was never started";
        return;
      }

      # Check that the start and end contexts have the same name.
      $context               = lc($context);
      my $start_context_name = $self->{current_node}->name; 
      unless ($start_context_name eq $context) {
        $self->{errstr} = "'$file_or_dir_name' line $line_number closes " .
                          "context '$context' that should close context " .
                          "'$start_context_name'";
        return;
      }

      # Move the current node up to the mother node.
      $self->{current_node} = $mother;

      next;
    }

    # At this point a new directive or context node will be created.
    my $new_node = $self->{current_node}->new_daughter;
    $new_node->filename($file_or_dir_name);
    $new_node->line_number($line_number);

    # If the line begins with <, then it is starting a context.
    if (my ($context, $value) = $_ =~ m#^<\s*(\S+)\s+(.*)>\s*$#) {
      $context = lc($context);

      # Remove any trailing whitespace in the context's value as the
      # above regular expression will match all after the context's
      # name to the >.  Do not modify any internal whitespace.
      $value   =~ s/\s+$//;

      $new_node->name($context);
      $new_node->value($value);
      $new_node->orig_value($value);

      # Set the current node to the new context.
      $self->{current_node} = $new_node;

      next;
    }

    # Anything else at this point is a normal directive.  Split the
    # line into the directive name and a value.  Make sure not to
    # collapse any whitespace in the value.
    my ($directive, $value) = $_ =~ /^(\S+)(?:\s+(.*))?$/;
    $directive                   = lc($directive);

    $new_node->name($directive);
    $new_node->value($value);
    $new_node->orig_value($value);

    # If there is no value for the directive, then move on.
    unless (defined $value and length $value) {
      next;
    }

    my @values = $new_node->get_value_array;

    # Go through all of the value array elements for those elements
    # that are paths that need to be optionally pre-transformed, then
    # made absolute using ServerRoot and then optionally
    # post-transformed.
    my $value_path_index = $directive_value_path_element_pos{$directive};
    my @value_path_indexes;
    if (defined $value_path_index and $value_path_index =~ /^-?\d+$/) {
      if (substr($value_path_index, 0, 1) eq '-') {
        @value_path_indexes = (abs($value_path_index) .. $#values);
      } else {
        @value_path_indexes = ($value_path_index);
      }
    }

    for my $i (@value_path_indexes) {
      # If this directive takes a path argument, then make sure the path
      # is absolute.
      if ($new_node->value_is_path($i)) {
	# If the path needs to be pre transformed, then do that now.
	if (my $pre_transform_path_sub = $self->{pre_transform_path_sub}) {
	  my ($sub, @args) = @$pre_transform_path_sub;
	  my $new_path     = &$sub($self, $directive, $values[$i], @args);
	  if (defined $new_path and length $new_path) {
	    $values[$i] = $new_path;
	  } else {
	    $values[$i] = DEV_NULL;
	  }
	  $new_node->set_value_array(@values);
	}

	# Determine if the file or directory path needs to have the
	# ServerRoot prepended to it.  First check if the ServerRoot
	# has been set then check if the file or directory path is
	# relative for this operating system.
	my $server_root = $self->{server_root};
	if (defined $server_root and
	    length  $server_root and
	    $new_node->value_is_rel_path) {
	  $values[$i] = "$server_root/$values[$i]";
	  $new_node->set_value_array(@values);
	}

	# If the path needs to be post transformed, then do that now.
	if (my $post_transform_path_sub = $self->{post_transform_path_sub}) {
	  my ($sub, @args) = @$post_transform_path_sub;
	  my $new_path     = &$sub($self, $directive, $values[$i], @args);
	  if (defined $new_path and length $new_path) {
	    $values[$i] = $new_path;
	  } else {
	    $values[$i] = DEV_NULL;
	  }
	  $new_node->set_value_array(@values);
	}
      }
    }

    # Always set the string value using the value array.  This will
    # normalize all string values by collapsing any whitespace,
    # protect \'s, etc.
    $new_node->set_value_array(@values);

    # If this directive is ServerRoot and node is the parent node,
    # then record it now because it is used to make other relative
    # pathnames absolute.
    if ($directive eq 'serverroot' and !$self->{current_node}->mother) {
      $self->{server_root} = $values[0];
      next;
    }

    # If this directive is AccessConfig, Include, IncludeOptional or
    # ResourceConfig, then include the indicated file(s) given by the
    # path.
    if ($directive eq 'accessconfig'    or
        $directive eq 'include'         or
        $directive eq 'includeoptional' or
        $directive eq 'resourceconfig') {
      unless ($new_node->value_is_path) {
        next;
      }
      unless ($self->_handle_include_directive($file_or_dir_name,
                                               $line_number,
                                               $directive,
                                               $values[0])) {
        return;
      }
    }

    next;
  }

  unless (close($fd)) {
    $self->{errstr} = "cannot close '$file_or_dir_name' for reading: $!";
    return;
  }

  return $self;

  # At this point check if all of the context have been closed.  The
  # filename that started the context may not be the current file, so
  # get the filename from the context.
  my $root = $self->{root};
  while ($self->{current_node} != $root) {
    my $context_name     = $self->{current_node}->name;
    my $attrs            = $self->{current_node}->attributes;
    my $context_filename = $attrs->{filename};
    my $line_number      = $attrs->{line_number};
    warn "$0: '$context_filename' line $line_number context '$context_name' ",
         "was never closed.\n";
    $self->{current_node} = $self->{current_node}->mother;
  }

  $self;
}

=item $c->root

Returns the root of the tree that represents the Apache configuration
file.  Each object here is a C<Apache::ConfigParser::Directive>.

=cut

sub root {
  $_[0]->{root}
}

=item $c->find_down_directive_names('directive', ...)

=item $c->find_down_directive_names($node, 'directive', ...)

In list context, returns the list all of C<$c>'s directives that match
the directive names in C<$node> and C<$node>'s children.  In scalar
context, returns the number of such directives.  The level here is in
a tree sense, not in the sense that some directives appear before or
after C<$node> in the configuration file.  If C<$node> is given, then
the search searches C<$node> and C<$node>'s children.  If C<$node> is
not passed as an argument, then the search starts at the top of the
tree and searches the whole configuration file.

The search for matching directive names is done without regards to
case.

This is useful if you want to find all of the CustomLog's in the
configuration file:

  my @logs = $c->find_down_directive_names('CustomLog');

=cut

sub find_down_directive_names {
  unless (@_ > 1) {
    confess "$0: Apache::ConfigParser::find_down_directive_names ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  my $self = shift;

  my $start;
  if (@_ and $_[0] and ref $_[0]) {
    $start = shift;
  } else {
    $start = $self->{root};
  }

  return () unless @_;

  my @found;
  my %names = map { (lc($_), 1) } @_;

  my $callback = sub {
    my $node = shift;
    push(@found, $node) if $names{$node->name};
    return 1;
  };

  $start->walk_down({callback => $callback});

  @found;
}

=item $c->find_siblings_directive_names('directive', ...)

=item $c->find_siblings_directive_names($node, 'directive', ...)

In list context, returns the list of all C<$c>'s directives that match
the directive names at the same level of C<$node>, that is siblings of
C<$node>.  In scalar context, returns the number of such directives.
The level here is in a tree sense, not in the sense that some
directives appear above or below C<$node> in the configuration file.
If C<$node> is passed to the method and it is equal to C<$c-E<gt>tree>
or if C<$node> is not given, then the method will search through
root's children.

This method will return C<$node> as one of the matches if C<$node>'s
directive name is one of the directive names passed to the method.

The search for matching directive names is done without regards to
case.

=cut

sub find_siblings_directive_names {
  unless (@_ > 1) {
    confess "$0: Apache::ConfigParser::find_siblings_directive_names ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  my $self = shift;

  my $start;
  if (@_ and $_[0] and ref $_[0]) {
    $start = shift;
  } else {
    $start = $self->{root};
  }

  return () unless @_;

  # Special case for the root node.  If the root node is given, then
  # search its children.
  my @siblings;
  if ($start == $self->{root}) {
    @siblings = $start->daughters;
  } else {
    @siblings = $start->mother->daughters;
  }

  return @siblings unless @siblings;

  my %names = map { (lc($_), 1) } @_;

  grep { $names{$_->name} } @siblings;
}

=item $c->find_siblings_and_up_directive_names($node, 'directive', ...)

In list context, returns the list of all C<$c>'s directives that match
the directive names at the same level of C<$node>, that is siblings of
C<$node> and above C<$node>.  In scalar context, returns the number of
such directives.  The level here is in a tree sense, not in the sense
that some directives appear before or after C<$node> in the
configuration file.  In this method C<$node> is a required argument
because it does not make sense to check the root node.  If C<$node>
does not have a parent node, then no siblings will be found.  This
method will return C<$node> as one of the matches if C<$node>'s
directive name is one of the directive names passed to the method.

The search for matching directive names is done without regards to
case.

This is useful when you find an directive and you want to find an
associated directive.  For example, find all of the CustomLog's and
find the associated ServerName.

  foreach my $log_node ($c->find_down_directive_names('CustomLog')) {
    my $log_filename = $log_node->name;
    my @server_names = $c->find_siblings_and_up_directive_names($log_node);
    my $server_name  = $server_names[0];
    print "ServerName for $log_filename is $server_name\n";
  }

=cut

sub find_siblings_and_up_directive_names {
  unless (@_ > 1) {
    confess "$0: Apache::ConfigParser::find_siblings_and_up_directive_names ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  my $self = shift;
  my $node = shift;

  return @_ unless @_;

  my %names = map { (lc($_), 1) } @_;

  my @found;

  # Recursively go through this node's siblings and all of the
  # siblings of this node's parents.
  while (my $mother = $node->mother) {
    push(@found, grep { $names{$_->name} } $mother->daughters);
    $node = $mother;
  }

  @found;
}

=item $c->errstr

Return the error string associated with the last failure of any
C<Apache::ConfigParser> method.  The string returned is not emptied
when any method calls succeed, so a non-zero length string returned
does not necessarily mean that the last method call failed.

=cut

sub errstr {
  unless (@_ == 1) {
    confess "$0: Apache::ConfigParser::errstr $INCORRECT_NUMBER_OF_ARGS";
  }

  my $self = shift;
  return $self->{errstr};
}

=item $c->dump

Return an array of lines that represents the internal state of the
tree.

=cut

my @dump_ref_count_stack;
sub dump {
  @dump_ref_count_stack = (0);
  _dump(shift);
}

sub _dump {
  my ($object, $seen_ref, $depth) = @_;

  $seen_ref ||= {};
  if (defined $depth) {
    ++$depth;
  } else {
    $depth = 0;
  }

  my $spaces = '  ' x $depth;

  unless (ref $object) {
    if (defined $object) {
      return ("$spaces '$object'");
    } else {
      return ("$spaces UNDEFINED");
    }
  }

  if (my $r = $seen_ref->{$object}) {
    return ("$spaces SEEN $r");
  }

  my $type              =  "$object";
  $type                 =~ s/\(\w+\)$//;
  my $comment           =  "reference " .
                           join('-', @dump_ref_count_stack) .
                           " $type";
  $spaces              .=  $comment;
  $seen_ref->{$object}  =  $comment;
  $dump_ref_count_stack[-1] += 1;

  if (UNIVERSAL::isa($object, 'SCALAR')) {
    return ("$spaces $$object");
  } elsif (UNIVERSAL::isa($object, 'ARRAY')) {
    push(@dump_ref_count_stack, 0);
    my @result = ("$spaces with " . scalar @$object . " elements");
    for (my $i=0; $i<@$object; ++$i) {
      push(@result, "$spaces index $i",
                    _dump($object->[$i], $seen_ref, $depth));
    }
    pop(@dump_ref_count_stack);
    return @result;
  } elsif (UNIVERSAL::isa($object, 'HASH')) {
    push(@dump_ref_count_stack, 0);
    my @result = ("$spaces with " . scalar keys(%$object) . " keys");
    foreach my $key (sort keys %$object) {
      push(@result, "$spaces key '$key'",
                     _dump($object->{$key}, $seen_ref, $depth));
    }
    pop(@dump_ref_count_stack);
    return @result;
  } elsif (UNIVERSAL::isa($object, 'CODE')) {
    return ($spaces);
  } else {
    die "$0: internal error: object of type ", ref($object), " not handled.\n";
  }
}

1;

=back

=head1 SEE ALSO

L<Apache::ConfigParser::Directive> and L<Tree::DAG_Node>.

=head1 AUTHOR

Blair Zajac <blair@orcaware.com>.

=head1 COPYRIGHT

Copyright (C) 2001-2005 Blair Zajac.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
