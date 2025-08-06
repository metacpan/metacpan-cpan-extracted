# linksite

Self-hosted Linktree clone

A very simple thing that I originally threw together in an hour or so. I
have since spent many hours turning it into something that other people
can also use.

## How to create your own link site

### The manual way

* Install this module using your favourite CPAN module installation mechanism (`cpanm App::LinkSite`)
* Create an `img` directory and in it put
  * An image to go at the top of the page
  * An image to use in the OpenGraph tags
* Create a file called `links.json`. You can either [copy mine](https://github.com/davorg-cpan/app-linksite/blob/main/example/links.json) and hack it about until it works, or read the details about the contents of the file below
* Run `linksite`
* Take the output (which will have been written to the `docs` subdirectory) and put it somewhere that's accessible over the internet

### The Github way

You can use GitHub, GitHub Actions and GitHub Pages together to automate a
lot of this work.

**Note:** If you take this approach (and I recommend it), you don't need to
install the CPAN module. All the work is done on a Docker container that
already has all of the required software installed.

* Create a new GitHub repo. Probably call it something like "links" or "my-links"
* Create the images and the `links.json` file described in "the manual way" section above
* Commit those files to your repo and push the commit to GitHub
* Copy the [sample GitHub workflow file](https://github.com/davorg-cpan/app-linksite/blob/main/example/build.yml) to `.github/workflows/build.yml` in your repo
* Commit the new file and push it to GitHub
* Go to the Pages settings in your GitHub repo (github.com/username/reponame/settings/pages)
* Set the build and deployment source as "GitHub Actions"
* Go to the GitHub Actions page for your repo (github.com/username/reponame/actions/workflows/build.yml)
* There will be a "Run workflow" button at the top right - push it
* Watch the logs for the build process
* Once the build is complete, your link site will be at username.github.io/reponame

Now you've set this up, any changes to your `links.json` file will trigger a
rebuild and redeployment of your link site.

## `links.json` syntax

The `links.json` file defines what appears on your link site. It has three sections:

* *Frontmatter* - which defines things about the whole site
* *Social Media Accounts* - the accounts that are listed here appear as a row of icons on your link site
* *Links* - the links that are listed here appear in a list below the social media icons

### Frontmatter

* **name:** Your name
* **handle:** Your default social media handle. If you use the same handle on most social media sites, then just put it here and you won't need to list it everywhere
* **image:** An image that appears at the top of the page
* **og_image:** An image that appears in the Open Graph tags for your page
* **site_url:** The URL of your site. This is optional. Without it, the program will probably do the right thing
* **desc:** A one-line description that appears on the site. You can use simple HTML in this
* **ga4:** If you want to track visitors using Google Analytics, then put your site key here

### Socials

A list of social networks that you use. This is a list of items. Each item
can contain some of these.

* **service:** The name of the social media network
* **handle:** The handle you use on this social media network. This can be omitted if it's the same as the default handle you have set in the frontmatter
* **url:** If the link to your social media account is particularly complex (and I'm looking at you, Mastodon), then you can just put the complete link here. In most cases, you can omit this

In many cases, you can just give a list of social media network names.

    "social" : [{
      "service" : "facebook"
    }, {
      "service" : "x-twitter"
    }, {
      "service" : "linkedin"
    }]

## Links

This is a list of links that will be displayed below the social media icons.

* **title:** The title to display for the link
* **subtitle:** An optional subtitle for the link (displayed in smaller type below the title)
* **link:** The link itself
* **new:** An optional flag to mark a link as new (`"new": 1`). This will display the link with a red "New" next to it

## Demo

My links - https://links.davecross.co.uk/
