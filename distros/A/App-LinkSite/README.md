# App::LinkSite

Generate a small, self-hosted links page from a JSON file. App::LinkSite is a
Perl command-line application: it builds static HTML and CSS that you can serve
from any static web host. No Perl installation is needed on the web server.

The page includes a profile, social icons, links, optional section headings,
Open Graph metadata, and JSON-LD structured data. See the
[live example](https://links.davecross.co.uk/).

For development and architecture, see
[CONTRIBUTING.md](https://github.com/davorg-cpan/app-linksite/blob/main/CONTRIBUTING.md).
Coding agents should start with
[AGENTS.md](https://github.com/davorg-cpan/app-linksite/blob/main/AGENTS.md).

## Build your first page

Install Perl 5.26 or later and App::LinkSite using your usual CPAN client:

```sh
cpanm App::LinkSite
mkdir my-links
cd my-links
```

Save this as `links.json` in that directory:

```json
{
  "name": "Example Person",
  "handle": "example",
  "desc": "Things I make and places to find me.",
  "site_url": "https://links.example.com/",
  "image": "",
  "og_image": "",
  "social": [
    { "service": "github" },
    { "service": "mastodon", "url": "https://social.example/@example" }
  ],
  "links": [
    {
      "title": "My website",
      "subtitle": "Projects and writing",
      "link": "https://example.com/",
      "new": 1
    },
    { "title": "Email", "link": "mailto:me@example.com" }
  ]
}
```

Replace the example names and URLs, then build:

```sh
linksite
```

The generated site is in `docs/`. To preview it locally with Python installed:

```sh
python3 -m http.server 8000 --directory docs
```

Open `http://localhost:8000/`. Upload the **contents** of `docs/` to your web
host's document root when ready. The page loads Bootstrap and Font Awesome
from public CDNs, so full styling and icons require network access.

Run builds in your content directory. The default output directory is relative
to your current working directory, as are image and `CNAME` lookups. Rebuilding
overwrites matching output files but does not remove old files.

## Configuration reference

The input is one JSON object encoded as UTF-8. The site-wide fields below are
top-level keys; there is no separate `frontmatter` object. Use arrays of
objects for `social`, `links`, and `sections`. Include `social: []` or `links: []` when you have no
entries; for a site containing only sections, use `links: []`.

### Site settings

| Key | Meaning |
| --- | --- |
| `name` | Display name, used in the heading, page title, and metadata. |
| `handle` | Default social handle; also shown with `@` in the page heading. Supply it without a leading `@`. |
| `desc` | Profile description. Newlines become line breaks in the page; simple HTML is also accepted. |
| `site_url` | Public URL of the page, including a trailing `/`, for Open Graph metadata. No URL is inferred when it is omitted. |
| `image` | Profile image filename inside your local `img/` directory. Use `""` or omit it for no image. |
| `og_image` | Social sharing image filename inside `img/`. Use `""` or omit it for no image. |
| `text_color` | Optional CSS color, for example `"#222222"`. Default body text is black. |
| `background_color` | Optional CSS color, for example `"#fafafa"`. Default body background is white. |
| `ga4` | Optional Google Analytics measurement ID, such as `G-EXAMPLE123`. Used for both the tag loader and configuration. Omit it or use an empty string to leave out analytics. |
| `utm` | Optional UTM settings for content links. Omit it or set it to `false` for no global tracking; `{}` enables defaults. See [Link tracking](#link-tracking). |

Color settings apply to the body; Bootstrap components and social icons have
their own styles.

### Images and custom domains

For `"image": "avatar.jpg"` and `"og_image": "preview.png"`, prepare:

```text
my-links/
  links.json
  img/
    avatar.jpg
    preview.png
  CNAME             # optional: hostname for GitHub Pages
```

Use filenames directly inside `img/`, without the `img/` prefix or a full URL.
Only the two named images are copied to `docs/img/`; the whole directory is not
copied. A `CNAME` file in the working directory is copied to `docs/CNAME`.
Configure your host and DNS separately for a custom domain.

### Social accounts

Each object in `social` accepts:

| Key | Meaning |
| --- | --- |
| `service` | One of the identifiers below; determines the URL pattern and Font Awesome icon. |
| `handle` | Optional override of the top-level handle. Handles are inserted as supplied, without URL encoding. |
| `url` | Optional complete profile URL; overrides the generated URL. Use this for other Mastodon instances or unusual profiles. |

These are the URL patterns implemented by this version; `{handle}` is replaced
by the account's handle:

| Service | Generated URL |
| --- | --- |
| `facebook` | `https://facebook.com/{handle}` |
| `x-twitter` | `https://twitter.com/{handle}` |
| `instagram` | `https://instagram.com/{handle}` |
| `tiktok` | `https://tiktok.com/@{handle}` |
| `linkedin` | `https://linkedin.com/in/{handle}` |
| `substack` | `https://{handle}.substack.com/` |
| `github` | `https://github.com/{handle}` |
| `medium` | `https://{handle}.medium.com/` |
| `reddit` | `https://reddit.com/user/{handle}` |
| `quora` | `https://quora.com/profile/{handle}` |
| `mastodon` | `https://fosstodon.org/@{handle}` |
| `threads` | `https://www.threads.net/@{handle}` |
| `bluesky` | `https://bsky.app/profile/{handle}` |
| `letterboxd` | `https://letterboxd.com/{handle}` |
| `lastfm` | `https://last.fm/user/{handle}` |
| `ko-fi` | `https://ko-fi.com/{handle}` |

Use `x-twitter` rather than `twitter`. A custom `url` changes the destination
but does not add an icon for an unsupported service. Social anchors include
`rel="me"`.

### Links

Each object in `links`, including links inside a section, accepts:

| Key | Meaning |
| --- | --- |
| `title` | Required link text. |
| `link` | Required destination URL; `mailto:` links work too. |
| `subtitle` | Optional smaller text beneath the title. |
| `new` | Optional truthy flag (`1` or `true`) that adds a red “New!” label. Defaults to false. |
| `utm` | Optional per-link UTM settings, merged over global settings; `false` or `null` disables tracking for this link. `{}` enables defaults even without global tracking. |

### Link tracking

UTM tracking is available from 0.2.0 and is opt-in. Existing configurations
continue to generate their original destinations. To enable tracking for
top-level and section links, add a top-level `"utm": {}`. This adds:

| Parameter | Default |
| --- | --- |
| `utm_source` | `linksite` |
| `utm_medium` | `referral` |
| `utm_campaign` | `profile` |
| `utm_content` | Slug of the link's `title`, for example `My Newsletter!` becomes `my-newsletter`. |

Title slugs use lowercase Unicode letters and numbers. Runs of spaces or
punctuation become a single hyphen, and leading/trailing hyphens are removed.
If nothing remains, `utm_content` is omitted. Links with the same title have
the same default content value; override it to distinguish them.

Override defaults globally or for an individual link using full `utm_*`
parameter names. For example, this fragment changes the source for all
content links and identifies one link separately:

```json
"utm": { "utm_source": "my-profile", "utm_campaign": "summer" },
"links": [
  {
    "title": "My newsletter",
    "link": "https://example.com/newsletter#subscribe",
    "utm": { "utm_content": "newsletter" }
  },
  {
    "title": "Untracked link",
    "link": "https://example.com/plain",
    "utm": false
  }
]
```

The first destination becomes
`https://example.com/newsletter?utm_campaign=summer&utm_content=newsletter&utm_medium=referral&utm_source=my-profile#subscribe`.
The second remains unchanged. An individual `"utm": {}` can also enable
tracking when it is disabled globally. Within a settings object, an empty
string or `null` omits that parameter; strings and numbers are supported,
and values are percent-encoded as UTF-8.

Existing URL parameters, including any existing UTM values, take precedence
and are preserved with their original encoding and order. Fragments remain
at the end. Only absolute `http://` and `https://` content links are tagged;
relative links, `mailto:`, `tel:`, and social profile URLs keep their original
destinations. The Perl `link` reader and JSON-LD keep the original URLs;
`tracked_link` returns the click destination. Tagged anchor attributes are
HTML-escaped.

This feature adds URL parameters; the destination's analytics system must
collect them. The page's `ga4` setting is separate and is not required for
UTM tagging. See [Google's campaign URL guidance](https://support.google.com/analytics/answer/10917952?hl=en)
and the complete [tracking example](https://github.com/davorg-cpan/app-linksite/blob/main/example/links-with-utm.json).

### Sections

Add a top-level `sections` array to group links:

```json
"sections": [
  {
    "title": "Projects",
    "links": [
      { "title": "My project", "link": "https://example.com/project" }
    ]
  },
  { "title": "Coming soon", "links": [] }
],
"links": [
  { "title": "Contact", "link": "mailto:me@example.com" }
]
```

This is a fragment to insert into the main JSON object. Non-empty sections
appear in their input order. Empty sections are hidden. When at least one
section has links, top-level links appear afterwards under “Other links”.
When all sections are empty or `sections` is omitted, top-level links appear
as a flat list. With no top-level links, “Other links” is omitted.

Full examples are in
[example/links.json](https://github.com/davorg-cpan/app-linksite/blob/main/example/links.json)
and
[example/links-with-sections.json](https://github.com/davorg-cpan/app-linksite/blob/main/example/links-with-sections.json).
Their image filenames and analytics values are placeholders; supply your own
images or clear those fields before building.

## Commands and alternate input files

```sh
linksite                     # build links.json into docs/
linksite --file profile.json  # build a different input file into docs/
linksite --help              # display usage
linksite --version           # display installed version
LINKSITE_DEBUG=1 linksite
```

Use `--file` for a different input filename or path. Quote paths containing
spaces; positional filenames are not supported:

```sh
linksite --file "content/my profile.json"
```

`--help` and `--version` display information without reading input or building,
including when combined with `--file`. Invalid options, such as `--file`
without a filename, return exit status 2 without building. Successful builds
and informational options return zero; input or build failures return non-zero.

Select a different output directory through the Perl API:

```sh
perl -MApp::LinkSite -e 'App::LinkSite->new(file => "profile.json", out => "public")->run'
```

Even with a different input path, images and `CNAME` are still read from the
current working directory. There are no CLI options for output directories
or template directories.

### Custom templates

Select a custom UTF-8 Template Toolkit source tree with an absolute `src` path:

```sh
perl -MApp::LinkSite -e 'App::LinkSite->new(file => "profile.json", src => "/absolute/path/to/templates", out => "public")->run'
```

Template files retain their source-relative directories and lose only the
final `.tt` suffix: `news/index.html.tt` generates `public/news/index.html`,
while `index.html.tt` generates `public/index.html`. Other assets keep their
relative paths and are copied unchanged.

When upgrading from a version older than 0.2.0, build into a fresh output
directory to avoid stale flattened template output. Old generated files
are not removed automatically.

## Build with Docker or GitHub Actions

To build with the image used by the sample workflow, run this from your
content directory with Docker installed:

```sh
docker run --rm -v "$PWD:/links" davorg/links:latest linksite
```

The bind mount receives the generated `docs/`. The image's default command
prints the installed module version; specify `linksite` to build. Files may be
owned by the container user. See
[docker/README.md](https://github.com/davorg-cpan/app-linksite/blob/main/docker/README.md)
for image-building details.

For GitHub Pages automation:

1. Create a content repository with `links.json`, any images under `img/`,
   and an optional `CNAME` file.
2. Copy
   [example/build.yml](https://github.com/davorg-cpan/app-linksite/blob/main/example/build.yml)
   to `.github/workflows/build.yml` in that repository.
3. If your default branch is not `main`, change both `push.branches` and
   the build job's `if` condition to use your branch name.
4. In the repository's Pages settings, select **GitHub Actions** as the source.
5. Run the workflow manually from the Actions tab with the configured branch
   selected, or push a watched change to that branch.

The sample runs `linksite` inside `davorg/links:latest`, uploads `docs/` as a
Pages artifact, and deploys it in a separate job. It uses the released module
in that image, not code from this source repository.
Pushes to the configured branch rebuild for changes to `links.json`, any
file under `img/`, `CNAME`, or `.github/workflows/build.yml`. Manual runs
on other branches skip the build and deployment.

**Hosting limitation:** the default template uses `/css/style.css` and
`/img/...`, which are relative to the domain root. A project URL such as
`https://username.github.io/my-links/` needs template changes for those assets
to load. Prefer a custom domain or a root site at `https://username.github.io/`.
Setting `site_url` alone does not change asset paths.

## Troubleshooting and current limits

| Symptom | What to check |
| --- | --- |
| Cannot read or decode the input | Run from the directory containing `links.json`; ensure it is valid JSON with the expected object and array shapes. There is no separate schema-validation command. |
| Missing image / copy failure | The filename must exist under `img/` in the working directory. The examples do not ship image files. |
| Page has no local CSS or profile image | Preview through a web server at its root; check the hosting-path limitation above. |
| Social icon or link is missing | Check the service identifier, profile handle, and whether the CDN stylesheet loads. |
| Old files remain after a rebuild | The builder does not clean the output directory. Use a new output directory or remove obsolete generated files yourself. |

The input JSON is copied into the published directory under its original
basename. Keep credentials and other private data out of it. Input values
in Open Graph and page-description metadata attributes are HTML-escaped.
The visible profile description still supports simple HTML and converts
newlines to line breaks. Other rendered fields have no general escaping or
sanitization, so use content you trust and review the generated page when
including HTML or quotes.

App::LinkSite uses Semantic Versioning (SemVer), with release numbers in
`MAJOR.MINOR.PATCH` form. See the
[versioning policy](https://github.com/davorg-cpan/app-linksite/blob/main/CONTRIBUTING.md#versioning)
for release and compatibility guidance.

App::LinkSite is free software under the same terms as Perl itself. Changes
are listed in
[Changes.md](https://github.com/davorg-cpan/app-linksite/blob/main/Changes.md).
