package Catmandu::Importer::MediaWiki;
use Catmandu::Sane;
use MediaWiki::API;
use Catmandu::Util qw(:is :check array_includes);
use URI::Escape;
use Moo;

#only generators that generate pages, and that have generators
my $generators = [qw(
    alllinks
    allpages
    allredirects
    alltransclusions
    backlinks
    categorymembers
    embeddedin
    exturlusage
    imageusage
    iwbacklinks
    langbacklinks
    pageswithprop
    prefixsearch
    random
    recentchanges
    watchlist
    watchlistraw
)];
my $default_args = {
    prop => "revisions",
    rvprop => "ids|flags|timestamp|user|comment|size|content|sha1|tags|userid|parsedcomment",
    rvlimit => 'max',
    gaplimit => 100,
    gapfilterredir => "nonredirects"
};
my $ns_map = {
    allpages => "gapnamespace",
    alllinks => "galnamespace",
    allredirects => "garnamespace",
    alltransclusions => "gatnamespace",
    backlinks => "gblnamespace",
    categorymembers => "gcmnamespace",
    embeddedin => "geinamespace",
    exturlusage => "geunamespace",
    imageusage => "giunamespace",
    iwbacklinks => undef,
    langbacklinks => undef,
    pageswithprop => undef,
    prefixsearch => "gpsnamespace",
    random => "grnnamespace",
    recentchanges => "grcnamespace",
    watchlist => "gwlnamespace",
    watchlistraw => "gwrnamespace"
};

has url => (
    is => 'ro',
    isa => sub { check_string($_[0]); }
);
#cf. https://www.mediawiki.org/wiki/API:Login
has lgname => ( is => 'ro' );
has lgpassword => ( is => 'ro' );
#cf. http://www.mediawiki.org/wiki/API:Lists
#cf. http://www.mediawiki.org/wiki/API:Query#Generators
has generate => (
    is => 'ro',
    isa => sub {
        array_includes($generators,$_[0]) or die("invalid generator");
    },
    lazy => 1,
    default => sub { "allpages"; }
);
has args => (
    is => 'ro',
    isa => sub { check_hash_ref($_[0]); },
    lazy => 1,
    default => sub { $default_args },
    coerce => sub {
        my $l = $_[0];
        my $h = is_hash_ref($l) ? +{ %$default_args,%$l } : $default_args;
        for(keys %$h){
            delete $h->{$_} unless defined $h->{$_};
        }
        $h;
    }
);
has mediawiki => (
    is => 'ro',
    lazy => 1,
    builder => '_build_mw'
);

with 'Catmandu::Importer';

sub _build_mw {
    my $self = $_[0];
    my $mw = MediaWiki::API->new( { api_url => $self->url() }  );

    if(is_string($ENV{LWP_TRACE})){
        $mw->{ua}->add_handler("request_send",  sub { shift->dump; return });
        $mw->{ua}->add_handler("response_done", sub { shift->dump; return });
    }

    $mw;
}
sub _fail {
    my $err = $_[0];
    die( $err->{code}.': '.$err->{details} );
}

sub generator {
    my $self = $_[0];

    my $generator = $self->generate();
    my $args = $self->args();

    sub {
        state $mw = $self->mediawiki();
        state $pages = [];
        state $cont_args = {};
        state $logged_in = 0;
        state $namespaces = [];
        state $namespace_key = $ns_map->{ $generator };
        state $siteinfo = {};

        unless($logged_in){
            #only try to login when both arguments are set
            if(is_string($self->lgname) && is_string($self->lgpassword)){
                $mw->login({ lgname => $self->lgname, lgpassword => $self->lgpassword }) or _fail($mw->{error});
            }
            $logged_in = 1;
        }

        #store continue arguments per namespace
        if(scalar(@$namespaces) == 0){
            #namespaces supported: true
            if(defined $namespace_key){

                if(is_string($args->{ $namespace_key })){
                    push @$namespaces,split(/\|/o,$args->{ $namespace_key });
                }
                else{
                    my $r = $mw->api({ action => "query", meta => "siteinfo", "siprop" => "namespaces|general" }) or _fail($mw->{error});
                    return unless defined $r;
                    $siteinfo =  $r->{query};
                    push @$namespaces,sort keys(%{ $siteinfo->{namespaces} });
                }
                $cont_args->{$_} = { continue => '' } for @$namespaces;
            }
            #namespaces supported: false
            else{

                push @$namespaces,"_none_";
                $cont_args->{_none_} = { continue => '' };

            }
        }

        return unless scalar(@$namespaces);

        if(scalar(@$pages)==0){
            #results for namespace are depleted: goto next
            unless(defined ($cont_args->{ $namespaces->[0] })){
                shift @$namespaces;
            }

            return unless scalar(@$namespaces);

            #look until you found a decent namespace
            my $res;
            while(scalar(@$namespaces)){
                my $a = {
                    %$args,
                    %{$cont_args->{ $namespaces->[0] } },
                    action => "query",
                    indexpageids => 1,
                    generator => $generator,
                    format => "json"
                };
                if(defined $namespace_key){
                    $a->{ $namespace_key } = $namespaces->[0];
                }
                #will work with generator in the future
                delete $a->{rvlimit};
                $res = $mw->api($a);
                if(!$res){
                    if ( $mw->{error}->{details} =~  /gapunknown_gapnamespace/o || $mw->{error}->{details} =~ /API has returned an empty array reference/o ){
                        shift @$namespaces;
                        return unless scalar(@$namespaces);
                        next;
                    }
                    _fail($mw->{error});
                }else{
                    last;
                }
            }


            return unless defined $res;

            $cont_args->{ $namespaces->[0] } = $res->{'continue'};

            if(exists($res->{'query'}->{'pageids'})){

                for my $pageid(@{ $res->{'query'}->{'pageids'} }){
                    #'titles, pageids or a generator was used to supply multiple pages, but the limit, startid, endid, dirNewer, user, excludeuser, start and end parameters may only be used on a single page.'
                    #which means: cannot repeat pageids when asking for full history
                    my $page = $res->{'query'}->{'pages'}->{$pageid};

                    #add source url
                    my $title = $page->{title};
                    $title =~ s/\s/_/go;

                    {
                        my $articlepath = $siteinfo->{general}->{articlepath};
                        $articlepath =~ s/\$1/${title}/;

                        #server:  http://localhost:8000
                        my $server = $siteinfo->{general}->{server};
                        #servername: localhost:8000
                        my $servername = $siteinfo->{general}->{servername};

                        my $url;
                        if( is_string($server) ){

                            $url = $server.$articlepath;

                        }
                        else{

                            my $base = $siteinfo->{general}->{base};
                            my $protocol = $base =~ /^https/o ? "https" : "http";
                            $url = "${protocol}://".$siteinfo->{general}->{servername}.$articlepath;

                        }

                        $page->{_url} = $url;

                    }

                    if(is_string($args->{rvlimit})){

                        my $a = {
                            action => "query",
                            format => "json",
                            pageids => $pageid,
                            prop => "revisions",
                            rvprop => $args->{rvprop},
                            rvlimit => $args->{rvlimit}
                        };
                        my $res2 = $mw->api($a) or _fail($mw->{error});
                        $page->{revisions} = $res2->{'query'}->{'pages'}->{$pageid}->{revisions} if $res2->{'query'}->{'pages'}->{$pageid}->{revisions};

                        #add source url
                        for my $revision(@{ $page->{revisions} } ){

                            $revision->{_url} = $page->{_url}."?oldid=".$revision->{revid};

                        }

                    }

                    push @$pages,$page;
                }
            }
        }

        shift @$pages;
    };
}

=head1 NAME

Catmandu::Importer::MediaWiki - Catmandu importer that imports pages from mediawiki

=head1 DESCRIPTION

This importer uses the query api from mediawiki to get a list of pages
that match certain requirements.

It retrieves a list of pages and their content by using the generators
from mediawiki:

L<http://www.mediawiki.org/wiki/API:Query#Generators>

The default generator is 'allpages'.

The list could also be retrieved with the module 'list':

L<http://www.mediawiki.org/wiki/API:Lists>

But this module 'list' is very limited. It retrieves a list of pages
with a limited set of attributes (pageid, ns and title).

The module 'properties' on the other hand lets you add properties:

L<http://www.mediawiki.org/wiki/API:Properties>

But the selecting parameters (titles, pageids and revids) are too specific
to execute a query in one call. One should execute a list query, and then
use the pageids to feed them to the submodule 'properties'.

To execute a query, and add properties to the pages in one call can be
accomplished by use of generators.

L<http://www.mediawiki.org/wiki/API:Query#Generators>

These parameters are set automatically, and cannot be overwritten:

action = "query"
indexpageids = 1
generator = <generate>
format = "json"

Additional parameters can be set in the constructor argument 'args'.
Arguments for a generator origin from the list module with the same name,
but must be prepended with 'g'.

=head1 ARGUMENTS

=over 4

=item generate

type: string

explanation:    type of generator to use. For a complete list, see L<http://www.mediawiki.org/wiki/API:Lists>.
                because Catmandu::Iterable already defines 'generator', this parameter has been renamed
                to 'generate'.

default: 'allpages'.

=item args

type: hash

explanation: extra arguments. These arguments are merged with the defaults.

default:

    {
        prop => "revisions",
        rvprop => "ids|flags|timestamp|user|comment|size|content",
        gaplimit => 100,
        gapfilterredir => "nonredirects"
    }

which means:

    prop             add revisions to the list of page attributes
    rvprop           specific properties for the list of revisions
    gaplimit         limit for generator 'allpages' (every 'generator' has its own limit).
    gapfilterredir   filter out redirect pages

=item lgname

type: string

explanation:    login name. Only used when both lgname and lgpassword are set.

L<https://www.mediawiki.org/wiki/API:Login>

=item lgpassword

type: string

explanation:    login password. Only used when both lgname and lgpassword are set.

=back

=head1 SYNOPSIS

    use Catmandu::Sane;
    use Catmandu::Importer::MediaWiki;

    binmode STDOUT,":utf8";

    my $importer = Catmandu::Importer::MediaWiki->new(
        url => "http://en.wikipedia.org/w/api.php",
        generate => "allpages",
        args => {
            prop => "revisions",
            rvprop => "ids|flags|timestamp|user|comment|size|content",
            gaplimit => 100,
            gapprefix => "plato",
            gapfilterredir => "nonredirects"
        }
    );
    $importer->each(sub{
        my $r = shift;
        my $content = $r->{revisions}->[0]->{"*"};
        say $r->{title};
    });

=head1 AUTHORS

Nicolas Franck C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Catmandu>, L<MediaWiki::API>

=cut

1;
