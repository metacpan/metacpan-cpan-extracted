## Dancer2::Plugin::Locale::Meta

Interface to use Locale::Meta in order to provide multilanguage support to dancer2 apps.


# NAME
Dancer2::Pluging::Locale::Meta

# DESCRIPTION

This plugin allow Dancer2 developers to use Locale::Meta package. This
Plugin is based on Dancer2::Plugin::Locale::Wolowitz plugin.

# SYNOPSIS

    use Dancer2;
    use Dancer2::Plugin::Locale::Meta;

### in your routes

#### Getting the translation
    get '/' => sub {
      my $greeting = loc("hello");
      template index.tt, { greeting => $greeting }
    }
#### Getting locale_meta attribute
    my $locale_meta = locale_meta

### in your template

    <% l('greeting') %>

### loading customized structure
To load a data structure, you need to define a hash ref supported by Locale::Meta.

eg. 
    my $structure = {
      "en" => {
        "goodbye"   => {
          "trans" => "bye",
        }
      },
      "es" => {
        "goodbye"   => {
          "trans" => "chao",
        }
      }
    };

In order to load the data use the keyword on your routes:

    load_structure($structure);

# CONFIGURATION
    plugins:
      Locale::Meta:
        fallback: "en"
        locale_path_directory: "i18n"
        lang_session: "lang"





