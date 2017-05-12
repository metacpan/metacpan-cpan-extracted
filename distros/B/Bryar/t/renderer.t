use Test::More 'no_plan';
use Cwd;
use_ok("Bryar::Renderer::TT");

# Test the generate_html method exists
ok(Bryar::Renderer::TT->can("generate"), "We can call generate");

# Let's bust it.
use Bryar;

my $bryar = Bryar->new(datadir=> cwd()."/t/");
my @documents = $bryar->{config}->source->all_documents($bryar->config);
my $page = $bryar->{config}->renderer->generate("html", $bryar, @documents);
like($page, qr/Boring.*second blog.*first blog/sm, "Page processed OK");
