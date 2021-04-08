package Connector::Role::LocalPath;
use Moose::Role;
use Template;
use utf8;

requires 'DELIMITER';

has file => (
    is => 'rw',
    isa => 'Str',
    );

has path => (
    is => 'rw',
    isa => 'Str',
    );


sub _render_local_path {

    my $self = shift;
    my $args = shift || [];
    my $data = shift;

    my $file;
    if ($self->path()) {
        my $pattern = $self->path();
        $self->log()->debug('Process template ' . $pattern);
        Template->new({})->process( \$pattern, { ARGS => $args, DATA => $data }, \$file) || die "Error processing file template.";
        # yes we allow paths here
        $file =~ s/[^\s\w\.\-\/\\]//g;
    } elsif ($self->file()) {
        my $pattern = $self->file();        
        $self->log()->debug('Process template ' . $pattern);
        Template->new({})->process( \$pattern, { ARGS => $args, DATA => $data }, \$file) || die "Error processing argument template.";
        if ($file =~ m{[^\s\w\.\-]}) {
            $self->log()->error('Target file name contains disallowed characters! Consider using path instead.');
            die "Target file name contains disallowed seperator! Consider using path instead.";
        }
    } elsif (ref $args && scalar @{$args}) {
        $file = join $self->DELIMITER(), @{$args};
    }

    return $file;    
}

1;

__END__;


=head1 Connector::Role::LocalPath

This role is used to generate file or pathnames from a template string
and the path arguments given. It also accepts additional data as a hash.

=head2 Parameters

=over

=item file

A template toolkit string to generate the filename to write to. The
arguments given as connector location are available in I<ARGS>, the
payload data in I<DATA>. The class will die if the result contains
any other characters than word, whitespace, dash or dot. 

=item path

Similar to file with slash and backslash also allowed. Disallowed 
characters will be removed and the sanitized string is returned.

=back
