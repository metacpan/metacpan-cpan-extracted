package Dancer2::Plugin::LiteBlog::Scaffolder::Data;
sub build { 0.03 }
1;
__DATA__
--- public/css/liteblog/single-page.css
/* Styling for the post entry page */


/* The small navigation bar */

.hero-banner {
    display: flex;
    align-items: center;
    justify-content: center;
    transition: height 0.3s ease;
    background-color: #2D2D2D;

    position: sticky;
    top: 0;
    z-index: 1000; 
}

.hero-banner-wrapper {
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: 100%;
    padding: 10px 20px; /* side padding */
}

.site-title {
	font-family: "Roboto", "Open Sans", sans-serif;
    font-size: 1.5em;
	color: #999;
    font-weight: normal;
}

/* Navigation elements */

nav {
    display: flex;
    gap: 1em;
	font-family: "Roboto", "Open Sans", sans-serif;
}

nav a {
    text-decoration: none;
	color: #B0B0B0;
    padding: 0.5em 1em;
    transition: background-color 0.3s, color 0.3s;
}

nav a:hover {
    color: #2D2D2D; /* Dark background color for text on hover */
    background-color: #FFA500; /* Orange color on hover */
}

/* Small version of the site's logo */

.avatar-logo {
	margin-top: 5px;
    width: 50px;
    border-radius: 50%;
    box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
}

/* End of Hero Banner */

/* START single page post-header style */
.post-header {
    display: flex;
	height: 100%;
    position: relative;

	border-bottom: 5px solid #e2e2e2; 
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); /* Soft shadow for depth */
    padding-bottom: 20px; /* Space at the bottom */

    flex-direction: column;
    justify-content: space-between; /* This will push the title to the center and meta to the bottom */
    align-items: center;
    background-size: cover;
    background-position: center;
    max-width: 100%;
    border-radius: 5px;
    position: relative; /* Needed for the overlay and for the meta's absolute positioning */
    margin-bottom: 20px;
}

.post-header::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.6); /* Black overlay to ensure text readability */
    z-index: 1;
}

.post-header .header-content {
	flex-grow: 1;
    display: flex;
    flex-direction: column;
    justify-content: center;  
    z-index: 2; /* To ensure it's above the ::before pseudo-element */
    width: 100%; /* Ensure it takes the full width of the container */
}

.post-title {
    font-size: 3.5em;
    margin-bottom: 20px; /* Can adjust this for spacing, if needed */
	margin-top: 80px;

	text-shadow: 1px 1px 1px rgba(255, 255, 255, 0.7); /* Subtle text outline for depth */
    text-align: center;
    color: #fff;
    z-index: 2;
}

ul.post-meta {
    align-self: flex-end; /* Align to the end of the flex container */
    z-index: 3;
    
	padding: 0;
	margin: 0px; 
	margin-right: 10px; 
	margin-top: 40px;
    margin-bottom: 10px;

    list-style-type: none; /* Remove bullet points */
    display: flex; /* Arrange child items horizontally */
    gap: 15px; /* Space between meta items */
    justify-content: flex-end; /* Aligns meta to the right */

}

.post-meta li {
    background: rgba(220, 220, 220, 0.8); /* 7220% opaque white */
    margin: 0;
    border-radius: 10px 10px 10px 10px; /* top-left, top-right, bottom-right, bottom-left */

	font-family: 'Roboto', 'Arial', sans-serif;
    font-size: 0.9em; 
    padding: 3px 10px; 
}

.post-meta li a, .post-meta li {
    color: #4d4d4d;
    text-decoration: none;
}

.post-meta li.clickable:hover a {
    color: #fff; /* Changing text color on hover */
}
.post-meta li.clickable:hover
{
    background-color: rgba(255, 165, 0, 0.8); /* transparent orange color */

    color: #fff; /* Changing text color on hover */
}
.post-meta li.clickable a:hover {
    text-decoration: none; /* Removing underline on hover */
    color: #fff; /* Changing text color on hover */
}

/* END single page post-header style */

/* post-header when there is no featured image */

.post-header.no-featured-image {
    background: #f0f0f0; /* Light background */
    color: #333; /* Darker text color for better contrast on light bg */
    
}

/* Override the dark overlay when no featured image */
.post-header.no-featured-image::before {
    background: rgba(255, 255, 255, 0); /* Transparent overlay */
}

/* Adjust the title color for better readability on light background */
.post-header.no-featured-image .post-title {
    color: #333;
    text-shadow: 1px 1px 1px rgba(255, 255, 255, 0.7); /* Subtle text outline for depth */
    padding: 20px 0; /* Padding for visual space */
}

/* Adjust the meta background and text color for light theme */
.post-header.no-featured-image .post-meta li {
    background: rgba(0, 0, 0, 0.05); /* Very light background for the meta */
    border: 1px solid #ddd; /* Subtle border for definition */
    color: #333;
}

.post-header.no-featured-image .post-meta li.clickable:hover,
.post-header.no-featured-image .post-meta li.clickable:hover a {
    background-color: #e2e2e2; /* Light grey for hover */
    color: #333; /* Dark text for contrast */
}

/* If the links need to be a different color, update here */
.post-header.no-featured-image .post-meta li a {
    color: #333;
}

.post-header.no-featured-image .header-content {
    align-items: center; /* Center align the content for a polished look */
    text-align: center; /* Center the text for a modern feel */
}

.post-header.no-featured-image .post-meta li.clickable a:hover {
    color: #333; 
}



/* Tags and Meta Data of the Page */

.tags {
    display: flex;
    flex-wrap: wrap;
    list-style-type: none;
    margin: 10px 0 20px 0; /* spacing above and below the tags */
    margin: 0;
    padding: 0;
    gap: 6px; /* reduced space between tags */
    justify-content: flex-end; /* aligns the tags to the right */
}

.tags li {
    font-family: 'Roboto', 'Arial', sans-serif;
    margin: 0;
    display: inline-block; /* makes the li inline */
    padding: 2px 8px; /* reduced padding */
    background-color: #f7f7f7; /* light gray background */
    border: 1px solid #eaeaea; /* subtle border color */
    border-radius: 10px; /* adjusted rounded corners */
    font-size: 12px; /* smaller font size */
    color: #777; /* softer color */
}

.tags a {
    text-decoration: none;
    color: inherit; /* takes color from parent element */
    transition: background-color 0.3s ease, color 0.3s ease;
    display: block; /* fills the li container */
    height: 100%;
    width: 100%;
    padding: inherit; /* takes padding from parent element */
    box-sizing: border-box; /* ensures that padding does not increase the size */
}

.tags a:hover {
    background-color: #eaeaea; /* subtle hover effect */
    color: #555; /* slightly darker text */
}

/* End of tags */

/* The main content area : the page/ the article */

.container {
  max-width: 800px;
  margin: 40px auto;
  margin-top: 20px;
  padding: 0 20px;
}

/* Cover image */

.cover-image-container {
    width: 100%;                  /* Full width of the container */
    height: 33.33vh;             /* 1/3rd of the viewport height */
    display: flex;               /* Use flexbox to center the image */
    align-items: center;         /* Vertically center the image */
    justify-content: center;     /* Horizontally center the image */
    overflow: hidden;            /* Hide parts of the image that exceed the container */
}

.cover-image-container img {
    max-width: 100%;             /* Image takes the maximum width possible */
    max-height: 100%;            /* Image takes the maximum height possible */
    object-fit: cover;           /* Resize the image to cover the container, keeping its aspect ratio */
    object-position: center;     /* Center the image within the container */
}



/* Titles */
h1 {
  font-family: "Roboto", "Open Sans", sans-serif;
  font-weight: bold;
  font-size: 2.5em;
  color: #444;
  text-align: center;
  margin-bottom: 1em;
}

h2, h3, h4 {
  font-family: "Roboto", "Open Sans", sans-serif;
}

/* Article Content */
article p, li, blockquote {
    font-family: 'Merriweather', source-serif-pro, Georgia, Cambria, "Times New Roman", Times, serif;
    line-height: 1.6;
    font-size: 17px;
    color: #333; /* A soft black */
    font-weight: 400; /* Regular font weight */
    margin: 1.4em 0; /* This gives some space between paragraphs for better readability */
}

/* List elements in the article */

article ul, /* target ul inside the article */
article ol { /* target ordered lists as well just in case you have any */
    margin: 1em 0;
    padding-left: 1.2em; /* provides space for bullet points or numbers */
}

article li {
    line-height: 1.2; /* slightly more than regular text for readability */
    margin: 0.5em;
}

/* Blockquotes should stand out from regular content to indicate emphasis or a quote from another source. Here's a typical styling that differentiates blockquotes from regular text: */
article blockquote {
    margin: 1.5em 0;
    padding: 0.5em 1em; /* some padding to the quote */
    border-left: 4px solid #eee; /* a subtle left border to highlight the quote */
    font-style: italic; /* italicize the quote */
    font-size: 1.1em; /* make it slightly larger */
    color: #666; /* a soft gray to differentiate from regular text */
    line-height: 1.5; /* a slightly increased line height for readability */
    background-color: #fafafa; /* a subtle background can also help the quote stand out */
}


/* Responsiveness for the single-page layout */

/* When the screen size is less than or equal to 768px (Tablet and below) */
@media (max-width: 768px) {

    #hero-banner {
        display: none;
    }

    #mobile-header {
        display: flex;
    }

    article {
        font-size: 14px; /* Slightly reduce font size for better fit */
        padding-left: 3rem;
        padding-right: 3rem;
        padding-bottom: 3rem;
    }

    article h1, article h2, article h3, article h4 {
        /* Adjusting header sizes for smaller screens */
        font-size: calc(1em + 2vw); /* This allows the font size to scale slightly based on viewport width */
    }

    article p, li, blockquote {
        font-size: 17px;
    }

    article blockquote {
        padding: 0.5em;
        border-left-width: 3px;
    }

    .container {
        padding: 0;
        margin: 0;
    }

    .post-meta {
        margin: 0;
        padding: 0;
        padding-right: 10px;
    }
}

/* When the screen size is less than or equal to 480px (Mobile) */
@media (max-width: 480px) {
    article {
        font-size: 16px; /* Further reduce font size for mobile */
        padding: 10px;
    }

    article ul, article ol {
        padding-left: 1em;
    }

    article .tags {
        /* Adjusting tags for smaller screens */
        flex-direction: column; /* stack tags vertically */
        align-items: flex-start;
    }

    article .tags li {
        margin-bottom: 0.5em; /* space between tags */
    }

    .header-content {
        margin: 0 !important;
        padding: 0 !important;
    }
}

--- views/liteblog/index.tt
[% IF no_widgets %]
<section id="main-page">
    <div class="main-page-content">
        <h2>Great! Now it's time to enable some widgets</h2>
        <p>
            Welcome to your LiteBlog site! Everything is working just fine. You just have to enable some widgets in your Dancer2 config.

            Try adding those lines in your <code>config.yml</code> file and restart your app.
        </p>

        <pre>
liteblog:
  title: "My Liteblog Site"
  logo: "/images/liteblog.jpg"
  feature:
    highlight: 1
  navigation:
    - label: "Home"
      link: "/"
    - label: "Tech"
      link: "/blog/tech"
  widgets:
    - name: activities
      params: 
        source: "activities.yml"
    - name: blog
      params:
        title: "Read my Stories"
        root: "articles"
        </pre>
    </div>
</section>
[% ELSE %]

[% FOREACH widget IN widgets %]
[% INCLUDE "liteblog/widgets/$widget.view" %]
[% END %]

[% END %]


--- public/images/liteblog.jpg
/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsK
CwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQU
FBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wAARCAGQAZADASIA
AhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQA
AAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3
ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWm
p6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEA
AwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSEx
BhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElK
U1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3
uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD9U6KK
KACiikPSgApa8Vtv2rvBkP7QWo/B7WTc+HfFccUM+mtqQVLfV0kTcPszhjlgcjY2CSpwDg17QGDH
igB1FFFABRRRQAUUUUAFFFFABRRRQAUUhOKQtgCgB1FN389KztZ8QW2hJbNcpOwuJ0t08iFpfmbp
naDtHqx4FNK+hMpRguaT0NOkzSFxmuc1DxoLDxlpugf2RqM/22FphqEUObaLGflds8Hj07j1pqLl
oiJ1IU0nJ+X3nSHNITSB81y3iDxZqOk+KtD0u18P3WpWmoMwn1CJgI7THdh3/T8aIxc3ZE1a0KMe
ae10vv0OrJxQDmm7s1z114lvIPGlloq6Jdy2dxbNO+rKR5ETA8Rt3yf60kubYqdSNNJy6ux0Qbmn
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

--- articles/blog-meta.yml
---
categories:
  - tech
  - perl
featured_posts:
  - "tech/first-article"
  - "contact"
  - "tech/second-article-tech"
  - "failed/does-not-exist"

--- views/liteblog/widgets/blog.tt
<!-- Blog Cards -->
<section id="blog">
    <div class="blog-header">
        <h2>[% widget.title %]</h2>
    </div>
[% INCLUDE 'liteblog/widgets/blog-cards.tt' %]
</section>

--- public/css/liteblog/activities.css

/* Restore full width */
section#activities {
    max-width: 2000px;
    margin: auto;
}

#activity-welcome {
    width: calc(66.66% - 20px); /* 2/3 of the width minus the margin */
    margin: 0 auto; /* Center the card horizontally */
}

#activities {
    display: flex;
    flex-wrap: wrap;
    gap: 20px;
    justify-content: center;
    padding: 40px 20px;

}

.activity-card {
    background-color: #ffffff;
    
    flex: 1 0 calc(33.333% - 20px); /* this ensures the card takes up 1/3 of the width minus the gap */
    min-width: 280px; /* this is the minimum width each card will have */
    max-width: 320px; /* this is the maximum width each card will have */

    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    text-align: center;
    padding: 20px;
    border-radius: 5px;
    font-size: 14px;
}

.activity-card pre {
    margin:0;
    padding: 0;
    text-align: left;
}

.activity-card img {
    width: 100%;
    height: 160px; /* Fixed height of 60px */
    object-fit: cover; /* Maintain aspect ratio */
    object-position: center; /* Center the image horizontally and vertically */
}

.activity-card h2 {
    margin-top: 0;
}

.activity-card p {
    text-align: left;
}

@media screen and (max-width: 768px) {
    .activity-card {
        width: calc(30% - 20px);
    }
}

@media screen and (max-width: 680px) {
    .activity-card {
        width: 100%;
        max-width: 280px;
    }
}


--- articles/tech/first-article/featured.jpg
/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsK
CwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQU
FBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wAARCAHJAyADASIA
AhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQA
AAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3
ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWm
p6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEA
AwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSEx
BhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElK
U1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3
uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD4NQe1
KyU5RQwr66x+cX1I9vtTStSkU09aVhpke32pSlPAzRg0rDuR7aTb71JSbaLDuMK0mMVJto20rBcj
op5FJgUWHcbTl6UhWhRyKQzzLXP+Qzef9dW/nWf/AA1f13/kM3n/AF0P86ofw18xP4mffUvgj6IS
ijk16r44+BFx4F+F/g3xrd+JNHng8UktaaXH5yXsUIUbp3idFPliTfGHXcrFDtJBFQaHlVFey+Nf
2atR8BeM/Bnh/VfFXh6RvFPlyW1zp8k9ybaGRlEMk8CxedH5iurqnl79pGVB4rA+OPwV1j4C+Mov
DGvzW8+p/Y47qV7NXMALlvljlZQswG3BePKbty5ypwAec0UUUAFFFFABRRRQAUUUUAFFFFABRRRQ
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

--- views/liteblog/single-page.tt
<div class="container">

  [% IF page_image %]
  <section class="post-header" style="background-image: url('[% page_image %]');">
  [% ELSE %]
  <section class="post-header no-featured-image">
  [% END %]

  <div class="header-content">
    <h1 class="post-title">[% page_title %]</h1>

    [% IF meta %]
      <ul class="post-meta">
      [% FOREACH m IN meta %]
        [% IF m.link %]
        <li class="clickable"><a href="[% m.link %]/">[% m.label %]</a></li>
        [% ELSE %]
        <li>[% m.label %]</li>
        [% END %]
      [% END %]
    </ul>
    [% END %]
  </div> <!-- END div header-content -->
  </section> <!-- END section post-header -->

  <article class="main-content">
  [% content %]
  </article> <!-- END article main-content -->

</div> <!-- END div container -->

--- public/css/liteblog.css
/* Our common colors for the Liteblog theme */
:root {
    --primary-color: #007BFF;
    --primary-hover: #0056b3;
    --text-color: #333;
    --background-color: #f4f4f4;
    --header-bg-color: #2d2d2d;
    --link-color: #007BFF;
    --link-hover-color: #0056b3;
}

body {
    font-family: 'Roboto', 'Arial', sans-serif;
    background-color: var(--background-color);

    margin: 0;
    padding: 0;

    font-size: 16px;
    line-height: 1.3;
}

h1, h2, h3, h4, h5, h6 {
    font-weight: 600; /* slightly bold but not too heavy */
}
h1 {
    font-size: 2.5rem;
}
h2 {
    font-size: 2rem;
}
h3 {
    font-size: 1.75rem;
}

h1.site-title {
    font-size: 1.5rem;
    text-align: center;
}

a {
    color: var(--link-color);
    text-decoration: none; /* Remove underline */
    transition: color 0.3s ease; /* Smooth color transition */
}
a:hover {
    color: var(--link-hover-color);
}

button, .btn {
    background-color: var(--primary-color);
    color: #fff;
    border: none;
    padding: 10px 20px;
    border-radius: 5px;
    cursor: pointer;
    transition: background-color 0.3s ease;
}
button:hover, .btn:hover {
    background-color: var(--primary-hover);
}

/* Accessibility rules */
a:focus, button:focus, .btn:focus {
    outline: 3px solid rgba(0, 123, 255, 0.5);
    outline-offset: 2px;
}

/* Header Menu */
/* CSS for the mobile header */
#mobile-menu-container {
    position: relative; /* to hold the popup menu */
}

#mobile-header {
    display: none;
    background-color: #2d2d2d;
    color: #ffffff;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    z-index: 10; /* Adjust z-index as needed */
    align-items: center; /* Center vertically */
    justify-content: space-between; /* space out the logo, title, and menu */
    flex-direction: row; /* Default flex-direction */
    padding: 5px;
}

#menu-toggle {
	margin-left: auto;
	margin-right: 20px;
    flex: none;
}

.site-title {
    margin: 0;
    flex-grow: 1; /* allows the title to take available space */
    text-align: left; /* align the site name to the left */
    padding: 0 10px; /* spacing around the site title */
}

.hamburger-menu {
    cursor: pointer;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    height: 24px; /* adjust height of the whole menu */
}

.hamburger-menu .bar {
    background-color: #ccc; /* color of the bar */
    height: 4px; /* thickness of each bar */
    width: 32px; /* width of each bar */
    border-radius: 2px; /* rounded edges */
}

/* The Hamburger Menu */
#mobile-navigation-menu {
    z-index: 9999; /* on top of other content */
    display: flex;
    flex-direction: column;
    background-color: #f5f5f5; 
    position: absolute;
    top: 100%;
    left: 0;
    right: 0;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1); 
    
    /* display: none; */
    visibility: hidden;
    opacity: 0;
    transition: visibility 0s, opacity 0.2s linear;
}

#mobile-navigation-menu.open {
    visibility: visible;
    opacity: 1;
    transition-delay: 0s; /* apply the transition immediately when opening */
}

.mobile-nav a {
    padding: 10px 20px;
    text-decoration: none;
    text-align: center;
    color: #333;
    border-bottom: 1px solid #ddd; /* separator between items */
}

.mobile-nav a:last-child {
    border-bottom: none; /* remove separator for the last item */
}

.mobile-nav a:hover {
    background-color: #ddd; /* change hover color as desired */
}

#avatar-icon {
    display: inline-block;
    margin-left: 5px; 
    width: 38px;
    height: 38px;
    border-radius: 50%;
    overflow: hidden;
    margin-right: 10px;
}

#avatar-icon img {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

#site-title-button a {
    color: #ccc;
}

#site-title-button {
    background: none;
    border: none;
    font-size: 22px;
    cursor: pointer;
    margin: auto;
    flex: 1; /* Expand to fill available space */
    text-align: center; /* Center text horizontally */
}

/* Home Page Layout */

#hero {
    background-color: #2d2d2d;
    text-align: center;
    padding: 50px 0;
    padding-bottom: 1.5rem;
}

#avatar {
    width: 150px;
    height: 150px;
    border-radius: 50%;
    margin-bottom: 20px;
}

h1 {
    color: #ffffff;
    margin: 0;
}

h3.site-baseline {
    margin: 0;
    margin-top: 1rem;
    padding: 0;
    color: #777;
    font-weight: normal;
}


/* make an element clickable with a zoom-in effect */
.clickable-div {
    /* Effect on mouse over */
    cursor: pointer; /* Add pointer cursor for clickability */
    transition: transform 0.2s, box-shadow 0.2s; /* Add transition for hover effect */
}

.clickable-div:hover {
    transform: scale(1.1); /* Apply a 10% zoom effect on hover */
    box-shadow: 0 8px 12px rgba(0, 0, 0, 0.2); /* Add a shadow effect on hover */
}

#hero a {
    text-decoration: none;
} 

/* For the default content when the website is empty */
section#main-page {
    width: 80%;
    max-width: 800px;
    margin: auto;
}

/* For mobile responsiveness */

@media screen and (max-width: 768px) {
    
    body {
        font-size: 14px;
    }
    h1, h2, h3 {
        line-height: 1.4;
    }

    img {
        max-width: 100%;
        margin: auto;
    }
}

--- activities.yml
---
- name: "LinkedIn"
  link: '#'
  image: '/images/LiteBlog.jpg'
  desc: "Checkout my LinkedIn profile. This is an example. Feel free to change it in <code>activities.yml</code>."
- name: "GitHub"
  link: "https://github.com/PerlDancer"
  desc: "This is the Dancer GitHub Official account. It's a good time to Star the <a href=\"https://github.com/PerlDancer/Dancer2\">Dancer2</a> project!  This is an example. Feel free to change it in <code>activities.yml</code>."

--- views/liteblog/widgets/activities.tt
<!-- Activity Cards -->
<section id="activities">
    [% FOREACH a IN widget.elements %]
        [% IF a.link %]
        <div class="activity-card clickable-div" id="activity-[% a.name %]">
            [% IF a.image %]
            <a href="[% a.link %]"><img width="300" height="300" src="[% a.image %]" alt="[% a.name %]"></a>
            [% END %]
        [% ELSE %]
        <div class="activity-card" id="activity-[% a.name %]">
            <img width="300" height="300" src="/images/[% a.name %].jpg" alt="[% a.name %]">
        [% END %]
            <h2>[% a.name %]</h2>
            <p>[% a.desc %] </p>
        </div> <!-- END activity-card -->

        [% IF a.link %]
        <script type="text/javascript">
        // JavaScript code to make the blog-card clickable
        document.getElementById('activity-[% a.name %]').addEventListener('click', function() {
            window.location.href = '[% a.link %]';
        });
        </script>
        [% END %]
    [% END %]
</section> <!-- END activities section -->

--- public/css/liteblog/blog.css
/* Blog Cards */

#blog {
    background-color: #2d2d2d;
    color: #ffffff;
    padding: 40px 0;
}

.blog-header {
    text-align: center;
    margin-bottom: 20px;
}

.blog-header h2 {
    font-size: 24px;
    margin: 0;
}

.blog-cards {
    display: flex;
    flex-wrap: wrap;
    gap: 20px;
    justify-content: center;
    padding: 20px;
}

.blog-card {
    position: relative; /* Needed for absolute positioning of the ribbon */
    
    width: calc(40% - 20px);
    min-width: 350px; 
    max-width: 420px !important;
    
    background-color: #ffffff;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    text-align: center;
    padding: 20px;
    border-radius: 5px;
    margin-bottom: 20px;
    color: #333;
    overflow: hidden; /* Hide overflowing ribbon */
    margin: 0;
    padding: 0;

    cursor: pointer; /* Add pointer cursor for clickability */
    transition: transform 0.2s, box-shadow 0.2s; /* Add transition for hover effect */
}

.blog-card p.post-excerpt {
    font-style: italic;
    font-size: 0.9em;
    text-align: left;
}

/* Add a hover effect for the blog card */
.blog-card:hover {
    transform: scale(1.1); /* Apply a 10% zoom effect on hover */
    box-shadow: 0 8px 12px rgba(0, 0, 0, 0.2); /* Add a shadow effect on hover */
}

.blog-card img {
    width: 100%;
    height: 120px; /* Fixed height of 60px */
    object-fit: cover; /* Maintain aspect ratio */
    object-position: center; /* Center the image horizontally and vertically */
}

.blog-card p {
    margin: 1em;
    margin-bottom: 2em;
}

.blog-card h3 {
    font-size: 20px;
    margin: 1em;
    color: #4d4d4d;
}

.blog-card .category-ribbon {
    background-color: #f16522; /* Adjust color as needed */
    color: #ffffff;
    padding: 5px 10px;
    border-radius: 3px;
    margin-bottom: 10px;
    display: inline-block;
}

/* Add styles for the category container */
.category-container {
    position: absolute; /* Position within the .blog-card */
    top: 0;
    right: 0;
    transform: translate(50%, -50%); /* Center the ribbon */
}

/* Add styles for the ribbon */
.category-ribbon {
    background-color: #f16522; /* Adjust color as needed */
    color: #ffffff;
    padding: 5px 20px; /* Adjust size as needed */
    border-radius: 3px;
    position: relative;
    z-index: 1; /* Place the ribbon above content */
    transform: translateX(40%) rotate(45deg); /* Adjust the translateX value as needed */
    transform-origin: top right; /* Rotate around the top right corner */
    top: 80px;
    right: 85px;
    width: 110px;

    text-align: center;
    font-size: 14px; /* Adjust font size as needed */
    line-height: 1.2; /* Adjust line height as needed */
}

/* Ensure the ribbon text is readable */
.category-ribbon::before {
    content: "";
    position: absolute;
    top: -4px;
    left: 0;
    border-width: 5px 5px 0;
    border-style: solid;
    border-color: #f16522 transparent transparent transparent;
}

.blog-button {
    text-align: center;
    margin-top: 20px;
}

.blog-button a {
    background-color: #f16522; /* Adjust color as needed */
    color: #ffffff;
    padding: 10px 20px;
    border-radius: 5px;
    text-decoration: none;
    font-weight: bold;
    font-size: 16px;
}


@media screen and (max-width: 768px) {
    .blog-card {
        width: calc(85% - 20px);
        max-width: 420px;
    }
}

@media screen and (max-width: 480px) {
    .blog-card {
        width: 100%;
        max-width: 420px;
    }
}


--- articles/tech/first-article/meta.yml
---
title: "A super Tech Blog Post"
tags:
  - perl
  - dancer
  - blog
image: "featured.jpg"
excerpt: "An example of an article for you to see easily how to write content for your Liteblog site."

--- articles/tech/first-article/content.md

Welcome to your Liteblog site. This is an example of an article written under
the <code>tech</code> category. It is written in Markdown format.

You can freely edit or remove this article, it is just there to help you get
started with Liteblog conventions.

## The 'Blog' widget

The blog engine of Liteblog is super simple and minimalist. There is no database
at all. Everything (regarding content or even settings) is done via static files
(either YAML or Markdown).

The blogging system is handled via a Widget which is responsible for finding
articles, listing them in the appropriate category pages, rendering them, etc.

Here is a setting that enables the blogging widget: 

<pre><code class="yaml">liteblog:
  ...
  widgets:
    - name: blog
      params:
        title: "Read my Stories"
        root: "articles"
</code></pre>

In this case, <code>root</code> is the parent directory where the Blog widget
will look for content. 

You can inspect this folder in your current app, the scaffolder already
populated everything you need.

## Articles and Pages in Liteblog

In Liteblog, articles and pages are almost the same thing. The only difference
is their location:

  * articles are located under a sub-folder that represents their category (in
    this example, we are under the <code>tech</code> category, hence the article
    is under the <code>/blog/tech</code> prefix.
  * pages are located at the top-level directory of the content folder.

As you can see, an article or a page is represented by three elements: 

  1. the directory of the article (equivalent to its slug in the path)
  2. the meta.yml file, where you can set all appropriate meta-data of the
     article (its title, some tags, or even a featured image).
  3. the content itself (written in Markdown format), located in
     <code>content.md</code>

## About images integration in your articles/page

It's super easy to include images in your articles. The recommended way to
proceed is simply to host your assets within the article/page directory and just
source them with a relative path. 

Just like that : 

<pre><code class="html">&lt;img src="featured.jpg" /&gt;</code></pre>

Which renders properly into that : 

<img src="featured.jpg" />

## It's your time to start editing!

Now, you know everything you need to write your own content. Why not starting by
editing this article? 

It's located in your app directory, under
<code>articles/tech/first-article/</code>

Happy Liteblogging!

## More about Liteblog

Feel free to [give Liteblog a star on CPAN Ratings](https://metacpan.org/dist/Dancer2-Plugin-LiteBlog) 
and [follow the official GitHub Project](https://github.com/sukria/Dancer2-Plugin-LiteBlog).


Voilà.

--- views/layouts/liteblog.tt
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    [% IF page_title %]
    
    <title>[% page_title %] | [% title %]</title>
   
    [% IF feature.highlight %] 
    <!-- Highlight JS Lib -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.5.0/styles/default.min.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.5.0/highlight.min.js"></script>
    [% END %]

    [% ELSE %]
    
    <title>[% title %]</title>
    
    [% END %]

    <link href="https://fonts.googleapis.com/css?family=Roboto:400,700|Lato:400,400i,700&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Merriweather:wght@400;700&family=Open+Sans:wght@400;600&display=swap" rel="stylesheet">

    <link rel="stylesheet" href="/css/liteblog.css">
    [% FOREACH w IN widgets %]
    <link rel="stylesheet" href="/css/liteblog/[% w.name %].css">
    [% END %]
    [% IF page_title %]
    <!-- a page_title is defined, let's load the single-page css -->
    <link rel="stylesheet" href="/css/liteblog/single-page.css">
    [% END %]
</head>
<body>

    <!-- This is the menu bar for small screens -->
    <header id="mobile-header">
    
      <!-- the site logo -->
      <div id="avatar-icon">
        [% IF logo %]
        <a href="/"><img src="[% logo %]" alt="[% title %] Logo"></a>
        [% ELSE %]
        <!-- Change the 'logo' setting (under the 'liteblog' config entry) to change this image -->
        <a href="/"><img src="/images/liteblog.jpg" alt="LiteBlog Logo"></a>
        [% END %]
      </div> <!-- END site logo -->

      <!-- the Site Title -->
      <button id="site-title-button">
        <a href="/">[% title %]</a>
      </button>

      [% IF navigation %]
      <div id="mobile-menu-container">
      <!-- the hamburger toggle button -->
      <div id="menu-toggle" class="hamburger-menu">
        <div class="bar"></div>
        <div class="bar"></div>
        <div class="bar"></div>
      </div> <!-- END hamburger toggle button -->
      </div>
      [% END %]

    [% IF navigation %]
    <!-- the hamburger menu -->
      <div id="mobile-navigation-menu" class="mobile-nav">
      [% FOREACH nav IN navigation %]
        [% IF nav.link %]
        <a class="mobile-nav-item" href="[% nav.link %]">[% nav.label %]</a>
        [% END %]
      [% END %]
      </div>
    [% END %] <!-- END hamburger menu -->


    </header> <!-- END mobile-header -->

    
    [% IF page_title %]
    <!-- single-page layout -->
    <div id="hero-banner" class="hero-banner">
      <div class="hero-banner-wrapper">
        <div class="site-title">[% title %]</div>
        [% IF navigation %]
        <nav>
          [% FOREACH nav IN navigation %]
            [% IF nav.link %]
              <a href="[% nav.link %]">[% nav.label %]</a>
            [% END %]
          [% END %]
        </nav>
        [% END %]
        [% IF logo %]
        <a href="/"><img src="[% logo %]" alt="[% title %] Logo" class="avatar-logo"></a>
        [% END %]
      </div>
    </div>
    
    [% ELSE %]
    <!-- Home Landing Page -->
    <section id="hero">
        <div class="header-wrapper">
            [% IF logo %]
            <a href="/"><img src="[% logo %]" alt="[% title %] Logo" id="avatar"></a>
            [% ELSE %]
            <!-- Change the 'logo' setting (under the 'liteblog' config entry) to change this image -->
            <a href="/"><img src="/images/liteblog.jpg" alt="LiteBlog Logo" id="avatar"></a>
            [% END %]
            <a href="/"><h1 class="site-title">[% title %]</h1></a>
            [% IF baseline %]
            <h3 class="site-baseline">[% baseline %]</h3>
            [% END %]
        </div>
    </section>
    [% END %]

[% content %]

[% IF page_title %]
<!-- mobile header detection for the 'hero-banner' (small) single page -->
<script type="text/javascript">
window.addEventListener('scroll', function () {
    var heroSection = document.getElementById('hero-banner');
    var mobileHeader = document.getElementById('mobile-header');

    if (window.scrollY > heroSection.clientHeight) {
        mobileHeader.style.display = 'flex';
    } else {
        mobileHeader.style.display = 'none';
    }
});
</script>
[% ELSE %]
<!-- mobile header detection for the 'hero' (big) landing page -->
<script type="text/javascript">
window.addEventListener('scroll', function () {
    var heroSection = document.getElementById('hero');
    var mobileHeader = document.getElementById('mobile-header');

    if (window.scrollY > heroSection.clientHeight) {
        mobileHeader.style.display = 'flex';
    } else {
        mobileHeader.style.display = 'none';
    }
});
</script>
[% END %]

[% IF navigation %]
<script type="text/javascript">
document.addEventListener('DOMContentLoaded', (event) => {
    // Get the elements
    const menuToggle = document.querySelector('#menu-toggle');
    const mobileMenu = document.querySelector('#mobile-navigation-menu');

    // Add event listener
    menuToggle.addEventListener('click', function() {
        // Toggle the .open class on the mobile menu
        mobileMenu.classList.toggle('open');
    });
});
</script>
[% END %]

[% IF feature.highlight %]
<script type="text/javascript">
document.addEventListener('DOMContentLoaded', (event) => {
    document.querySelectorAll('pre code').forEach((block) => {
        hljs.highlightBlock(block);
    });
});
</script>
[% END %]

    </body>
</html>

--- views/liteblog/widgets/blog-cards.tt
<div class="blog-cards">
        <!-- Individual blog post cards go here -->
        [% FOREACH p IN widget.elements %]
    <div class="blog-card" id="blog-[% p.slug %]">
        [% IF p.image %]
        <a href="[% p.permalink %]"><img class="post-image" src="[% p.image %]" alt="[% p.title %]"></a>
        [% END %]
        <h3 class="post-title">[% p.title %]</h3>

        [% UNLESS p.is_page %]
	    <div class="category-container">
            <div class="category-ribbon">[% p.category %]</div>
        </div>
        [% END %]
    
	    <p class="post-excerpt">[% p.excerpt %]</p>
    </div>

    <script type="text/javascript">
    // JavaScript code to make the blog-card clickable
    document.getElementById('blog-[% p.slug %]').addEventListener('click', function() {
        window.location.href = '[% p.permalink %]';
    });
    </script>
    [% END %]

</div> <!-- END blog-cards -->
    
[% IF widget.readmore_button %]
<div class="blog-button">
    <a href="/blog">[% widget.readmore_button %]</a>
</div>
[% END %]

