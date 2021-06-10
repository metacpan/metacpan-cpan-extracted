# dex - Directory Exec

---

*dex* is a command line utility that allows you to define commands in a file in any directory, and then execute those commands.

For example, this repository has a file called **.dex.yaml**:

```yaml
- name: build
  desc: "Run through the build process."
  shell:
    - rm -f App-dex-*.tar.gz
    - perl Makefile.PL
    - make manifest
    - make dist
- name: clean
  desc: "Remove artifacts"
  shell:
    - rm -rf App-dex-*.tar.gz MANIFEST META.yml MYMETA.* Makefile blib
```

Running dex, without any argument, in this repository's root directory will give a menu:

```bash
$ dex
build       : Run through the build process.
clean       : Remove artifacts
```

At this point, running `dex build` would run the shell commands listed in the yaml file.  Commands can also be nested:

```yaml
- name: dev
  desc: "Control a local development server."
  children:
    - name: start
      desc: "Start a local development server on docker."
      shell:
        - docker-compose --project-directory ./ -f Docker/compose-osx-devel.yaml up
    - name: stop
      desc: "Stop a local development server on docker."
      shell:
        - docker-compose --project-directory ./ -f Docker/compose-osx-devel.yaml down
    - name: reset
      desc: "Delete the database volume."
      shell:
        - docker-compose --project-directory ./ -f Docker/compose-osx-devel.yaml down -v
- name: test
  desc: "Run the tests."
  shell:
    - docker-compose --project-name testing --project-directory ./ -f Docker/compose-osx-test.yaml up
    - docker-compose --project-name testing --project-directory ./ -f Docker/compose-osx-test.yaml down
```

The children define further arguments that could be used, such as `dex dev start`, and the menu indents to show child commands:

```bash
$ dex
dev         : Control a local development server.
    start       : Start a local development server on docker.
    stop        : Stop a local development server on docker.
    reset       : Delete the database volume.
test        : Run the tests.
```
