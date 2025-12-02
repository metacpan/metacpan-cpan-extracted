#!/bin/bash
# save como create_structure.sh

# Criar diretórios
#mkdir -p AI-ActivationFunctions-0.01/lib/AI/ActivationFunctions
#mkdir -p AI-ActivationFunctions-0.01/t
#mkdir -p AI-ActivationFunctions-0.01/examples

# Mover para o diretório
#cd AI-ActivationFunctions-0.01

# Criar Makefile.PL (simplificado para teste)
cat > Makefile.PL << 'EOF'
use 5.010001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'AI::ActivationFunctions',
    VERSION_FROM  => 'lib/AI/ActivationFunctions.pm',
    ABSTRACT_FROM => 'lib/AI/ActivationFunctions.pm',
    AUTHOR        => 'Ulisses Manzo Castello <umcastello@gmail.com>',
    LICENSE       => 'perl_5',
    PREREQ_PM     => {
        'Test::More' => 0,
        'Exporter'   => 0,
        'Carp'       => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/test/ai-activationfunctions.git',
            },
        },
    },
);
EOF

echo "Estrutura criada! Agora copie os arquivos .pm e .t para os diretórios."
echo "Use os códigos que eu forneci anteriormente."
