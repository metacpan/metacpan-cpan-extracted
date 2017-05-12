package App::TemplateServer::Provider::Filesystem;
use Method::Signatures;
use File::Find;
use File::Spec;
use Moose::Util::TypeConstraints;
use Path::Class;
use Moose::Role;
use Scalar::Util qw(blessed);
use List::Util qw(reduce);
our ($a, $b);

with 'App::TemplateServer::Provider';

subtype 'ArrayRef[Path::Class::Dir]'
  => as 'ArrayRef[Defined]',
  => where { reduce { $a && blessed $b && $b->isa('Path::Class::Dir') } 
               (1, @{$_[0]}) 
           };

coerce 'ArrayRef[Path::Class::Dir]'
  => as 'ArrayRef[Str]'
  => via { [map { Path::Class::dir($_) } @$_] };

has '+docroot' => (
    isa        => 'ArrayRef[Path::Class::Dir]',
    required   => 1,
    coerce     => 1,
);

method list_templates {
    my @docroot = $self->docroot;
    
    my @files;
    #my $file_filter = $self->file_filter;
    for my $root (@docroot){
        find(sub { 
                 my $name = $File::Find::name;
                 push @files, File::Spec->abs2rel($name, $root) 
                   if -f $name; # && $name =~ /$file_filter/;
             },
             $root);
    }
    
    return @files;
};

1;
__END__

=head1 NAME

App::TemplateServer::Provider::Filesystem - role for templating systems that get templates from the filesystem (TT, Mason, etc.)

=head1 METHODS

=head2 list_templates

This method returns the template list by visiting each docroot
(recursively), and returning a list of regular files.  This is what
most template systems will want to do.

=head1 ATTRIBUTES

This role provides the following attributes:

=head2 docroot

This is an arrayref of directories where the templates that you are
"providing" are located.

=head1 SEE ALSO

L<App::TemplateServer::Provider>
