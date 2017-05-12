package Beagle::Cmd::Command::spread;
use Any::Moose;
use Beagle::Util;
extends qw/Beagle::Cmd::Command/;

has 'command' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'command which expects input from STDIN',
    traits        => ['Getopt'],
);

has 'dry-run' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'dry run',
    traits        => ['Getopt'],
    accessor      => 'dry_run',
);

has 'quiet' => (
    isa           => 'Bool',
    is            => 'rw',
    documentation => 'not prompt for confirmation',
    traits        => ['Getopt'],
);

has 'template' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'xslate template string',
    traits        => ['Getopt'],
);

has 'template-file' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'xslate template file path',
    accessor      => 'template_file',
    traits        => ['Getopt'],
);

has 'to' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'to whom?',
    traits        => ['Getopt'],
    default       => '',
);

has 'from' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'from who?',
    traits        => ['Getopt'],
    default       => '',
);

has 'subject' => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'subject',
    traits        => ['Getopt'],
    default       => '',
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub execute {
    my ( $self, $opt, $args ) = @_;
    $args = $self->resolve_ids( $args );
    die 'beagle spread id1 id2 [...]' unless @$args;

    die "can't use both --template and --template-file"
      if defined $self->template && defined $self->template_file;

    my $cmd = $self->command;
    for my $i (@$args) {
        my @ret = resolve_entry( $i, handle => current_handle() || undef );
        unless (@ret) {
            @ret = resolve_entry($i) or die_entry_not_found($i);
        }
        die_entry_ambiguous( $i, @ret ) unless @ret == 1;
        my $id    = $ret[0]->{id};
        my $bh    = $ret[0]->{handle};
        my $entry = $ret[0]->{entry};

        my $msg;

        my $template;

        if ( defined $self->template_file ) {
            my $name = $self->template_file;
            $name .= '.tx' unless $name =~ /\.tx$/;

            my $file;
            if ( -f $name ) {
                $file = $name;
            }
            else {
                for my $root( spread_template_roots ) {
                    if ( -f catfile( $root, $name ) ) {
                        $file = catfile( $root, $name );
                        last;
                    }
                }
                die "template file $name doesn't exist" unless defined $file;
            }

            $template = read_file($file);
        }
        elsif ( defined $self->template ) {
            $template = $self->template;
        }

        my $to = $self->to;
        my $from = $self->from || current_user();
        my $subject = $self->subject || $entry->summary(80);

        if ( defined $template ) {
            require Text::Xslate;
            my $tx = Text::Xslate->new(
                function => {
                    shorten => sub {
                        my $url = shift;
                        return $url unless defined $url;
                        return `shorten $url`;
                    },
                }
            );

            $msg = $tx->render_string(
                $template,
                {
                    handle  => $bh,
                    entry   => $entry,
                    id      => $id,
                    url     => $bh->info->url . '/entry/' . $id,
                    to      => $to,
                    from    => $from,
                    subject => $subject,
                }
            );
            $msg = encode_utf8( $msg );
        }
        else {
            require MIME::Entity;
            my %head = (
                'X-Beagle-URL'       => $bh->info->url . '/entry/' . $entry->id,
                'X-Beagle-Copyright' => $bh->info->copyright,
                'X-Beagle-Class'     => ref $entry,
            );

            my $mime = MIME::Entity->build(
                From    => encode( 'MIME-HEADER', $from ),
                Subject => encode( 'MIME-HEADER', $subject ),
                Data    => $entry->serialize( id => 1 ),
                Charset => 'utf-8',
                To => encode( 'MIME-HEADER', $to ),
                %head,
            );

            if ( $entry->format ne 'plain' ) {
                $mime->make_multipart;
                $mime->attach(
                    Data           => $entry->body_html,
                    'Content-Type' => 'text/html; charset=utf-8',
                );
            }

            my $atts = $bh->attachments_map->{$id};
            if ($atts) {
                $mime->make_multipart;
                for my $name ( keys %$atts ) {
                    $mime->attach(
                        Filename              => $name,
                        Data                  => $atts->{$name}->content,
                        Type                  => $atts->{$name}->mime_type,
                        'Content-Disposition' => "attachment; filename=$name",
                    );
                }
            }
            $msg = $mime->stringify;
        }

        $msg =~ s!\s+$!newline()!e;

        if ($cmd) {
            puts "going to call `$cmd` with input:", newline(),
              decode_utf8($msg)
              unless $self->quiet && !$self->dry_run;

            if ( !$self->dry_run ) {
                my $doit = 1;
                if ( !$self->quiet ) {
                    print "spread? (Y/n): ";
                    my $val = <STDIN>;
                    undef $doit if $val =~ /n/i;
                }

                if ($doit) {
                    my @cmd = Text::ParseWords::shellwords($cmd);
                    require IPC::Run3;
                    my ( $out, $err );
                    IPC::Run3::run3( [@cmd], \$msg, \$out, \$err, );
                    if ($?) {
                        die "failed to run $cmd: exit code is "
                          . ( $? >> 8 )
                          . ", out is $out, err is $err\n";
                    }
                    else {
                        print $out;
                    }
                }
            }
        }
        else {
            # yes, print utf8 encoded string all the time
            print $msg;
        }
    }
}


1;

__END__

=head1 NAME

Beagle::Cmd::Command::spread - spread entries

=head1 SYNOPSIS

    $ beagle spread --command /path/to/cmd id1 id2
    $ beagle spread --command /path/to/cmd --template '<: $url :>' id1 id2
    $ beagle spread --command /path/to/cmd --template-file short id1 id2

=head1 DESCRIPTION

C<spread> is used to broadcast entries via command specified by C<--command>.
By default, each entry will be converted to an MIME message,

You can use C<--template> or C<--template-file> to override this, in which
case each entry will be converted to a plain message based on the template.
(All the templates use C<Text::Xslate> engine.)

There are 3 items you can customize: C<from>, C<to> and C<subject>.

=over

=item from

In MIME messages, it's the value of head field C<From>.

By default it's the beagle owner's email( a.k.a the one in file info )

=item to

In MIME messages, it's the value of head field C<To>.

By default it's empty.

=item subject

In MIME messages, it's the value of head field C<Subject>.

By default it's the entry's summary with 80 chars at most.

=back

Vars bound to C<Text::Xslate> templates are:

        {
                    handle  => $bh,
                    entry   => $entry,
                    id      => $id,
                    url     => $bh->info->url . '/entry/' . $id,
                    to      => $to,
                    from    => $from,
                    subject => $subject,
        }

There are 3 template files in core: C<short>, C<long> and C<full>, which live
in C<share/spread_templates>, you can expand the templates root via config
item C<spread_templates_root>:

        $ beagle config --set spread_templates_root=/path/to/templates

=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

