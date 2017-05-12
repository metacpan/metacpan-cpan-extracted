#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use App::lcpan::Daemon;
use Plack::Builder;

App::lcpan::Daemon::_init(); # XXX allow customize 'cpan' and 'index_name'

my $app = builder {
    enable(
        "PeriAHS::ParseRequest",
        riap_uri_prefix  => '/App/lcpan/Daemon',
    );

    enable "PeriAHS::Respond";
};

=head1 SYNOPSIS

Start with a PSGI server of your choice:

 % plackup lcpand.psgi
 HTTP::Server::PSGI: Accepting connections at http://0:5000/

Then, request the server with any HTTP client, e.g.:

 % curl http://localhost:5000/
 .-----------------------------------------.
 | type       uri                          |
 |                                         |
 | function   author_dists                 |
 | function   author_mods                  |
 | function   author_rdeps                 |
 | function   author_rels                  |
 | function   authors                      |
 | function   authors_by_dist_count        |
 | function   authors_by_mod_count         |
 | function   authors_by_rdep_count        |
 | function   authors_by_rel_count         |
 | function   deps                         |
 | function   dist2rel                     |
 | function   distmods                     |
 | function   dists                        |
 | function   dists_by_dep_count           |
 | function   dzil_authors_by_bundle_count |
 | function   dzil_authors_by_plugin_count |
 | function   dzil_authors_by_role_count   |
 | function   dzil_bundles                 |
 | function   dzil_bundles_by_rdep_count   |
 | function   dzil_plugins                 |
 | function   dzil_plugins_by_rdep_count   |
 | function   dzil_roles                   |
 | function   dzil_roles_by_rdep_count     |
 | function   mod2dist                     |
 | function   mod2rel                      |
 | function   mods                         |
 | function   mods_by_rdep_count           |
 | function   mods_from_same_dist          |
 | function   modules                      |
 | function   namespaces                   |
 | function   rdeps                        |
 | function   releases                     |
 | function   rels                         |
 | function   stats                        |
 `-----------------------------------------'

 Tips:
 * To call a function, try:
     http://localhost:5000/api/dzil_plugins
 * Function arguments can be given via GET/POST params or JSON hash in req body
 * To find out which arguments a function supports, try:
     http://localhost:5000/api/mod2rel?-riap-action=meta
 * To find out all available actions on an entity, try:
     http://localhost:5000/api/namespaces?-riap-action=actions
 * This server uses Riap protocol for great autodiscoverability, for more info:
     https://metacpan.org/module/Riap

 % curl -g http://localhost:5000/api/authors?query:j='["PERLA%"]'
 .-----------------------.
 | ARYEH       PERLANCAR |
 `-----------------------'

 % curl -H 'Accept: application/json' -g http://localhost:5000/api/authors?query:j='["PERLA%"]'
 [200,"OK",["ARYEH","PERLANCAR"],{"riap.v":1.1}]


=head1 SEE ALSO

L<App::lcpan>

L<Riap::HTTP>

L<Perinci::Access::HTTP::Server>

=cut
