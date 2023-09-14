#!/usr/bin/env groovy
/* groovylint-disable CompileStatic, NoDef, VariableTypeRequired */

node {
  stage('src') {
    checkout scm
  }
}

script {
  cpan_audit()
  build_cpan()
  perl_critic()
  build_docs_cpan()
}
