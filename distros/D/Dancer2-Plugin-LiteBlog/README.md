
# Dancer2::Plugin::LiteBlog

**A minimalist, file-based blogging engine for Dancer2.**

Effortlessly transform local .md and .yml files into a sleek and responsive blog
without the need for a database.

---

## Introduction

`Dancer2::Plugin::LiteBlog` offers a straightforward approach to blogging by
integrating a lightweight engine with Dancer2 applications. By leveraging the
simplicity of flat files — specifically markdown and YAML — it dispenses with
the complexities of database management.

Publishing a blog post is as simple as updating a file in your appdir and
restarting your app. 

---

## Quick Start

Start by scaffolding Liteblog's assets in your Dancer2 application directory:

```bash
[in/your/dancerapp] $ liteblog-scaffold .
```

Then, edit your PSGI startup script: 


```
# in your app.psgi
use Dancer2;
use Dancer2::Plugin::LiteBlog;
liteblog_init();
```

Et voilà.

## Features

  * *Lightweight*: Ditch the database! Use flat files for efficient content management.
  * *Markdown & YAML*: Embrace these user-friendly formats for writing and configuration.
  * *Extensible*: Take advantage of the Widget interface to easily customize and extend functionalities.
  * *Modern and Responsive*: The scaffolder ensures that your blog is designed with contemporary standards in mind.


