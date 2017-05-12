package Net::ManageSieve::Siesh;

use warnings;
use strict;
use autodie qw(:all);
use File::Temp qw/tempfile/;
use Net::ManageSieve;
use IO::Prompt;
use parent qw(Net::ManageSieve);

sub starttls {
    my ( $self, @args ) = @_;
    if ( $self->debug() ) {
        eval {
            require IO::Socket::SSL;
            IO::Socket::SSL->import('debug3');
            1;
        } or do {
            die "Cannot load module IO::Socket::SSL\n";
          }
    }
    return $self->SUPER::starttls(@args);
}

sub movescript {
    my ( $self, $source, $target ) = @_;
    my $is_active = $self->is_active($source);

    ## We can't delete a active script, so we just deactivate it ...
    $self->deactivate() if $is_active;

    $self->copyscript( $source, $target );
    $self->deletescript($source);

    ## ... and activate the target later
    $self->setactive($target) if $is_active;
    return 1;
}

sub copyscript {
    my ( $self, $source, $target ) = @_;
    my $content = $self->getscript($source);
    return $self->putscript( $target, $content );
}

sub temp_scriptfile {
    my ( $self, $script, $create ) = @_;
    my ( $fh, $filename );
    eval { ( $fh, $filename ) = tempfile( UNLINK => 1 ); 1; } or do { die $@ };

    my $content = '';
    if ( $self->script_exists($script) ) {
        $content = $self->getscript($script);
    }
    elsif ( !$create ) {
        die "Script $script does not exists.\n";
    }

    print {$fh} $content;
    seek $fh, 0, 0;
    return $fh, $filename;
}

sub putfile {
    my ( $self, $file, $name ) = @_;
    my $script;
    open( my $fh, '<', $file );
    { local $/ = undef, $script = <$fh> }
    close $fh;
    my $length = length $script;
    $self->havespace( $name, $length );
    return $self->putscript( $name, $script );
}

sub getfile {
    my ( $self, $name, $file ) = @_;
    my $script = $self->getscript($name);
    open( my $fh, '>', $file );
    print {$fh} $script;
    return close $fh;
}

sub listscripts {
    my ( $self, $unactive ) = @_;
    my (@scripts);
    @scripts = @{ $self->SUPER::listscripts() };
    my $active = delete $scripts[-1];
    if ($unactive) {
        @scripts = grep { $_ ne $active } @scripts;
    }
    return @scripts;
}

sub deletescript {
    my ( $sieve, @scripts ) = @_;
    for my $script (@scripts) {
        $sieve->SUPER::deletescript($script);
    }
    return 1;
}

sub view_script {
    my ( $sieve, $script )   = @_;
    my ( $fh,    $filename ) = $sieve->temp_scriptfile($script);
    unless ($fh) { die $sieve->error() . "\n" }
    my $pager = $ENV{'PAGER'} || "less";
    no warnings 'exec';
    eval { system( $pager, $filename ); 1; } or do {
        print
"Error calling your pager application: $!\nUsing cat as fallback.\n\n";
        $sieve->cat($script);
    };
    return 1;
}

sub edit_script {
    my ( $sieve, $script ) = @_;
    my ( $fh, $filename ) = $sieve->temp_scriptfile( $script, 1 );
    my $editor = $ENV{'VISUAL'} || $ENV{'EDITOR'} || "vi";
    while (1) {
        system( $editor, $filename );
        eval { $sieve->putfile( $filename, $script ); 1; } or do {
            print "$@\n";
            ## There was maybe a parse error, if the user enters yes
            ## we reedit the file, otherwise we leave it by the next last
            next if prompt( "Re-edit script? ", -yn );
        };
        ## There was either no error with putfile or the user entered no
        last;
    }
    return close $fh;
}

sub activate {
    my ( $self, $script ) = @_;
    return $self->setactive($script);
}

sub deactivate {
    my $self = shift;
    return $self->setactive("");
}

sub is_active {
    my ( $self, $script ) = @_;
    return $self->get_active() eq $script;
}

sub get_active {
    my ($self) = @_;
    return $self->SUPER::listscripts()->[-1];
}

sub script_exists {
    my ( $self, $scriptname ) = @_;
    my %script = map { $_ => 1 } $self->listscripts;
    return defined( $script{$scriptname} );
}

1;    # End of Net::ManageSieve::Siesh

__END__

=head1 NAME

Net::ManageSieve::Siesh - Expanding Net::ManagieSieve beyond the pure protocol

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

Net::ManageSieve::Siesh expands Net::ManagieSieve beyond just implementing
the core RFC protocol. There are functions to upload and download files,
deactivating scripts, copy and move them etc.

    use Net::ManageSieve::Siesh;

    my $sieve = Net::ManageSieve::Siesh->new();
    $sieve->copy('script1','script2');
    $sieve->mv('script2','script3');
    $sieve->put('../script.txt','script4');
    $sieve->get('script1','../script.txt');

If you're just searching for a comamnd line interface to ManageSieve,
please take a look at C<siesh(1)>.

=head1 ERROR HANDLING

Unlike L<Net::ManagieSieve> this library just croaks in the case of error. Nothing wrong with that!

=head1 METHODS

=over 4

=item C<deactivate()>

Deactivates all active scripts on the server. This has
the same effect as using the function setactive with an empty string
as argument.

=item C<activate()>

Activates the scripts. This is identical to call setactive, but is easier
to remember.

=item C<movescript($oldscriptname,$newscriptname)>

Renames the script. This functions is equivalent to copying a script and
then deleting the source script. In case you try to move the currently
active script, it's deactivated first and later reactivated unter it's
new name.

=item C<copyscript($oldscriptname,$newscriptname)>

Copy the script C<$oldscriptname> to C<$newscriptname>.

=item C<temp_scriptfile($scriptname,$create)>

Calls tempfile from File::Temp and writes the content of C<$scriptname>
into the returned file. Returns the opened filehandle and the
filename. Unless C<$create> is true, return undef if the requested script
does not exist.

=item C<putfile($file,$scriptname)>

Uploads C<$file> with the name C<$scriptname> to the server. 

=item C<getfile($scriptname,$file)>

Downloads the script names <$scriptname> to the file specified by C<$file>.

=item C<listscripts()>

Returns a list of scripts. This function overwrites listscripts
provided by Net::ManageSieve in order to return a array. To get the
active script call get_active. If the first paramter is true only
the active script is not returned.

=item C<is_active($script)>

Returns true if $script is the currently active script and false if not.

=item C<get_active()>

Returns the name of the currently active script and the empty string if
there is not active script.

=item C<script_exists($script)>

Check if $script exists on server.

=item C<deletescript(@scripts)>

Delete all @scripts.

=back

=head1 AUTHOR

Mario Domgoergen, C<< <mario at domgoergen.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-app-siesh at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Siesh>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SEE ALSO

L<siesh(1)>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::ManageSieve::Siesh

You can also look for information at:

    L<http://www.math.uni-bonn.de/~dom/siesh/>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Mario Domgoergen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

