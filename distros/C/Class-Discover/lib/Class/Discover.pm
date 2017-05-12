package Class::Discover;

use strict;
use warnings;

our $VERSION = "1.000003";

use File::Find::Rule;
use File::Find::Rule::Perl;
use PPI;
use File::Temp;
use ExtUtils::MM_Unix;
use Carp qw/croak/;
use Path::Class;

sub discover_classes {
  my ($class, $opts) = @_;

  $opts ||= {};
  $opts->{keywords} ||= [qw/class role/];

  $opts->{keywords} = [ $opts->{keywords} ]
    if (ref $opts->{keywords} ||'') ne 'ARRAY';

  $opts->{keywords} = { map { $_ => 1 } @{$opts->{keywords}} };

  my @files;
  my $dir = dir($opts->{dir} || "");

  croak "'dir' option to discover_classes must be absolute"
    unless $dir->is_absolute;

  if ((ref $opts->{files} || '') eq 'ARRAY') {
    @files = @{$opts->{files}};
  } 
  elsif ($opts->{files}) {
    @files = ($opts->{files});
  }
  elsif ($dir) {
    my $rule = File::Find::Rule->new;
    my $no_index = $opts->{no_index};
    @files = $rule->no_index({
        directory => [ map { "$dir/$_" } @{$no_index->{directory} || []} ],
        file => [ map { "$dir/$_" } @{$no_index->{file} || []} ],
    } )->perl_module
       ->in($dir)
  }

  croak "Found no files!" unless @files;
  
  return [ map {
    my $file = file($_);
   
    local $opts->{file} = $file->relative($dir)->stringify;
    $class->_search_for_classes_in_file($opts, "$file")
  } @files ];
}

sub _search_for_classes_in_file {
  my ($class, $opts, $file) = @_;

  my $doc = PPI::Document->new($file);

  return map {
    $opts->{prefix} = "";
    $class->_search_for_classes_in_node($_, $opts);
  } grep {
    # Tokens can't have children
    ! $_->isa("PPI::Token")
  } $doc->children;
}

sub _search_for_classes_in_node {
  my ($self, $node, $opts) = @_;

  my $nodes = $node->find(sub {
      # Return undef says don't descend
      $_[1]->isa('PPI::Token::Word') && $opts->{keywords}{$_[1]->content}
                                     || undef
  });
  return unless $nodes;


  my @ret;
  for my $n (@$nodes) {
    my $type = $n->content;
    $n = $n->next_token;
    # Skip over whitespace
    $n = $n->next_token while ($n && !$n->significant);

    next unless $n && $n->isa('PPI::Token::Word');

    my $class = $n->content;

    $class = $opts->{prefix} . $class
      if $class =~ /^::/;

    # Now look for the '{'
    $n = $n->next_token while ($n && $n->content ne '{' );

    unless ($n) {
      warn "Unable to find '{' after 'class' somewhere in $opts->{file}\n";
      return;
    }

    my $cls = { $class => { file => $opts->{file}, type => $type } };
    push @ret, $cls;

    # $n was the '{' token, its parent is the block/constructor for the 'hash'
    $n = $n->parent;
  
    for ($n->children) {
      # Tokens can't have children
      next if $_->isa('PPI::Token');
      local $opts->{prefix} = $class;
      push @ret, $self->_search_for_classes_in_node($_, $opts)
    }

    # I dont fancy duplicating the effort of parsing version numbers. So write
    # the stuff inside {} to a tmp file and use EUMM to get the version number
    # from it.
    my $fh = File::Temp->new;
    $fh->print($n->content);
    $fh->close;
    my $ver = ExtUtils::MM_Unix->parse_version($fh);

    $cls->{$class}{version} = $ver if defined $ver && $ver ne "undef";

    # Remove the block from the parent, so that we dont get confused by 
    # versions of sub-classes
    $n->parent->remove_child($n);
  }

  return @ret;
}

1;

=head1 NAME

Class::Discover - detect MooseX::Declare's 'class' keyword in files.

=head1 SYNOPSIS

=head1 DESCRIPTION

This class is designed primarily for tools that whish to populate the
C<provides> field of META.{yml,json} files so that the CPAN indexer will pay
attention to the existance of your classes, rather than blithely ignoring them.

The version parsing is basically the same as what M::I's C<< ->version_form >>
does, so should hopefully work as well as it does.

=head1 METHODS

=head2 discover_classes

 Class::Discover->discover_classes(\%opts)

Takes a single options hash-ref, and returns a array-ref of hashes with the
following format:

 { MyClass => { file => "lib/MtClass.pm", type => "class", version => "1" } }

C<version> will only be present if the class has a (detected) version.
C<type> is the C<keyword> match that triggered this class.

The following options are understood:

=over

=item dir

The (absolute) directory from which files should be given relative to. If
C<files> is not passed, then the dir under which to search for modules.

=item files

Array-ref of files in which to look. If provided, then only these files will be
searched.

=item keywords

List of 'keywords' which are treated as being class declarators. Defaults to
C<class> and C<role>.

=item no_index

A hash of arrays with keys of C<directory> and C<file> which are ignored when
searching for packages.

=back

=head1 SEE ALSO

L<MooseX::Declare> for the main reason for this module to exist.

L<Module::Install::ProvidesClass>

L<Dist::Zilla>

=head1 AUTHOR

Ash Berlin C<< <ash@cpan.org> >>. (C) 2009. All rights reserved.

=head1 LICENSE 

Licensed under the same terms as Perl itself.

