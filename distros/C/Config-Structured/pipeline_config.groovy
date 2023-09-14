/* groovylint-disable CompileStatic */
jte {
  reverse_library_resolution = true
}

perl_conf {
  cpanfile_path = './'
}

libraries {
  audit
  apprise
  perl
  mkdocs {
    doc_base_dir = 'dev/docs/modules'
  }
}
