




package App::I18N::Web::Handler;
use warnings;
use strict;
use base qw(Tatsumaki::Handler);
use Tatsumaki;
use Tatsumaki::Error;
use Tatsumaki::Application;
use Template::Declare;

sub update_po {
    my ( $self, $pofile, $lexicon ) = @_;

    my $lme = App::I18N->lm_extract();
    $lme->read_po($pofile) if -f $pofile && $pofile !~ m/pot$/;

    # Reset previously compiled entries before a new compilation
    $lme->set_compiled_entries;
    $lme->compile(1);  # use gettext style

    my $o_lexicon = $lme->lexicon;
    for ( keys %$lexicon ) {
        print STDERR "Setup Entry: $_ : @{[  $lexicon->{ $_ } ]} \n";
        $o_lexicon->{ $_ } = $lexicon->{ $_ };
    }
    $lme->set_lexicon($o_lexicon);
    $lme->write_po($pofile);
}

sub post {
    my ($self,$path) = @_;
    my $params = $self->request->parameters->mixed;
    use List::MoreUtils qw(zip);

    my $pofile = $params->{pofile};
    my %lexicon = zip @{ $params->{'msgid[]'} } 
        ,@{ $params->{'msgstr[]'} };

    $self->update_po( $pofile , \%lexicon );
    $self->finish({ success => 1 });
}

sub get {
    my ( $self, $path ) = @_;
    $path ||= "/";
    $self->write( Template::Declare->show( $path, $self ) );
    $self->finish;
}



package App::I18N::Web::Handler::API;
use Encode;
use base qw(Tatsumaki::Handler);


sub db {
    my $self = shift;
    return $self->application->db;
}

=head1 Server API

/api/options

/api/podata

/api/entry/list[/{lang}]

/api/entry/unsetlist[/{lang}]

/api/entry/get/{id}

/api/entry/set/{id}/{msgstr}

/api/entry/insert/{lang}/{msgid}/{msgstr}

=cut

sub post {
    my ( $self, $path ) = @_;
    my ( $p1, $p2, @parts ) = split /\//, $path;
    my $pms = $self->request->parameters->mixed;

    if ( $p1 eq 'entry' && $p2 eq 'set' ) {
        my ( $id, $msgstr ) = ( $pms->{id}, $pms->{msgstr} );

        return $self->write( { error => 'Require msgstr and id' } ) unless $msgstr and $id;

        $msgstr = decode_utf8($msgstr);
        $self->application->db->set_entry( $id, $msgstr );
        return $self->write( { success => 1 } );
    }
    elsif( $p1 eq 'entry' && $p2 eq 'insert' ) {

    }
    elsif( $p1 eq 'translate' && $p2 eq 'google' ) {
        my $from = $pms->{from};
        my $to   = $pms->{to};




    }
    $self->write( { error => 1 } );
}

sub get {
    my ( $self, $path ) = @_;
    my ( $p1, $p2, @parts ) = split /\//, $path;
    my $params = $self->request->parameters->mixed;

    if ( $p1 eq 'podata' ) {
        my $langdata = $self->application->podata;
        return $self->write($langdata);
    }
    elsif ( $p1 eq 'skip_session' ) {
        $self->application->skip_session( 1 );
        return $self->write({ success => 1 });
    }
    elsif ( $p1 eq 'options' ) {
        return $self->write( $self->application->options );
    }
    elsif ( $p1 eq 'entry' && $p2 eq 'insert' ) {
        my ( $lang, $msgid, $msgstr ) = @parts;

        return $self->write( { error => 'Require language, msgid or msgstr' } ) unless $msgid and $msgstr and $lang;

        $msgstr = decode_utf8($msgstr);

        my $existed = $self->db->find( $lang, $msgid );
        return $self->write( { error => 'MsgID Exists', record => $existed } ) if $existed;

        $self->application->db->insert( $lang, $msgid, $msgstr );
        return $self->write( { success => 1, recordid => $self->application->db->dbh->last_insert_id( undef, undef, 'po_string', 'msgid' ) } );
    }
    elsif ( $p1 eq 'entry' && $p2 eq 'unsetlist' ) {
        my $lang      = shift @parts;
        my $entrylist;
        $entrylist = $self->application->db->get_unset_entry_list($lang);
        return $self->write( { entrylist => $entrylist } );
    }
    elsif ( $p1 eq 'entry' && $p2 eq 'list' ) {
        my $lang      = shift @parts;
        my $entrylist;
        $entrylist = $self->application->db->get_entry_list($lang);
        return $self->write( {
                entrylist => $entrylist } );
    }
    elsif ( $p1 eq 'entry' && $p2 eq 'get' ) {
        my $id = shift @parts;

        return $self->write( { error => 'Require ID' } ) unless $id;

        my $entry = $self->application->db->get_entry($id);
        return $self->write($entry);
    }
    elsif ( $p1 eq 'entry' && $p2 eq 'set' ) {
        my $id     = shift @parts;
        my $msgstr = shift @parts;

        return $self->write( { error => 'Require msgstr and id' } ) unless $msgstr and $id;

        $msgstr = decode_utf8($msgstr);
        $self->application->db->set_entry( $id, $msgstr );
        return $self->write( { success => 1 } );
    }

    $self->write( { error => 'Method Error' } );
}

1;
