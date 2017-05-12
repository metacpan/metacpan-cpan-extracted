
package CouchDB::Deploy::Process;

use strict;
use warnings;

our $VERSION = $CouchDB::Deploy::VERSION;

use Carp            qw(confess);
use CouchDB::Client;
use File::Spec;
use Data::Compare   qw(Compare);
*_SAME = \&Compare;

sub new {
    my $class = shift;
    my $server = shift;
    return bless {
        server  => $server,
        client  => CouchDB::Client->new(uri => $server),
    }, $class;
}

sub createDBUnlessExists {
    my $self = shift;
    my $dbName = shift;
    
    $dbName .= '/' unless $dbName =~ m{/$};
    if (not $self->{client}->dbExists($dbName)) {
        $self->{db} = $self->{client}->newDB($dbName)->create();
        return 1;
    }
    else {
        $self->{db} = $self->{client}->newDB($dbName);
        return 0;
    }
}

use Data::Dumper;
sub addDocumentUnlessExistsOrSame {
    my $self = shift;
    my $id = shift;
    my $data = shift || {};
    my $newAttach = shift || {};
    
    my $db = $self->{db};
    if (not $db->docExists($id)) {
        $db->newDoc($id, undef, $data, $newAttach)->create();
        return 1;
    }
    else {
        my $doc = $db->newDoc($id)->retrieve();
        my $content = $doc->data;
        my $origAttach = $doc->attachments;
        if (keys %$origAttach and keys %$newAttach) {
            # compare attachments only if the rest isn't already different
            if (_SAME($content, $data)) {
                # the length is not the same, the names are not the same, or the content types are not the same
                if (
                    scalar(keys(%$origAttach)) != scalar(keys(%$newAttach)) or
                    grep({ not exists $origAttach->{$_} } keys %$newAttach) or
                    grep({ $origAttach->{$_}->{content_type} ne $newAttach->{$_}->{content_type} } keys %$newAttach)
                ) {
                    return _UPDATE($doc, $data, $newAttach);
                }
                # we have to fall back to comparing content
                else {
                    for my $att (keys %$newAttach) {
                        my $b64 = $newAttach->{$att}->{data};
                        if ($b64 ne $doc->toBase64($doc->fetchAttachment($att))) {
                            return _UPDATE($doc, $data, $newAttach);
                        }
                    }
                }
            }
            else {
                return _UPDATE($doc, $data, $newAttach);
            }
        }
        else {
            if (not _SAME($content, $data)) {
                return _UPDATE($doc, $data);
            }
        }
    }
    return 0;
}

sub _UPDATE {
    my ($doc, $data, $newAttach) = @_;
    $doc->attachments($newAttach);
    $doc->data($data);
    $doc->update();
    return 2;
}

sub addDesignDocUnlessExistsOrSame {
    my $self = shift;
    my $id = shift;
    my $data = shift;
    
    my $db = $self->{db};
    if (not $db->designDocExists($id)) {
        $db->newDesignDoc($id, undef, $data)->create();
        return 1;
    }
    else {
        my $dd = $db->newDesignDoc($id)->retrieve();
        if (not _SAME($dd->data, $data)) {
            $dd->data($data)->update();
            return 2;
        }
        return 0;
    }
}

sub getFile {
    my $self = shift;
    my $file = shift;
    
    $file = File::Spec->rel2abs( 
        $file,
        File::Spec->rel2abs(
            File::Spec->catpath( (File::Spec->splitpath($0))[0,1], '' )
        )
    );
    open my $F, "<", $file or die "Can't open file: $file";
    my $content = do { local $/ = undef; <$F> };
    close $F;
    return CouchDB::Client::Doc->toBase64($content);
}

1;

=pod

=head1 NAME

CouchDB::Deploy::Process - The default processor for deploying to CouchDB

=head1 SYNOPSIS

    use CouchDB::Deploy;
    ...

=head1 DESCRIPTION

This module does the actual dirty job of deploying to CouchDB. Other backends could
replace it (though that's not supported yet) and it can be used by other frontends.

=head1 METHODS

=over 8

=item new $SERVER

Constructor. Expects to be passed the server to which to deploy.

=item createDBUnlessExists $NAME

Creates the DB with the given name, or skips it if it already exists. Returns true
if it did do something.

=item addDocumentUnlessExistsOrSame $ID, $DATA?, $ATTACH?

Creates the document with the given ID and optional data and attachments. If the 
document exists it will do its best to find out if the version in the database is
the same as the current one (including attachments). If it is the same it will be
skipped, otherwise it will be updated. On creation it returns 1, on update 2, and
if nothing was done 0.

=item addDesignDocUnlessExistsOrSame $ID, $DATA

Creates the design doc with the given ID and data. On creation it returns 1, 
on update 2, and if nothing was done 0.

=item getFile $PATH

Returns the content of the file in a form suitable for usage in CouchDB attachments.
Dies if it can't find the file.

=back

=head1 AUTHOR

Robin Berjon, <robin @t berjon d.t com>

=head1 BUGS 

Please report any bugs or feature requests to bug-couchdb-deploy at rt.cpan.org, or through the
web interface at http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CouchDb-Deploy.

=head1 COPYRIGHT & LICENSE 

Copyright 2008 Robin Berjon, all rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as 
Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may 
have available.

=cut

