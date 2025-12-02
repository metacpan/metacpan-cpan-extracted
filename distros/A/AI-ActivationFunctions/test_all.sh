# 1. Crie a estrutura
#mkdir -p AI-ActivationFunctions-simple/lib/AI
#mkdir AI-ActivationFunctions-simple/t
#mkdir AI-ActivationFunctions-simple/examples
#cd AI-ActivationFunctions-simple

# 2. Copie os arquivos acima para seus respectivos diretórios

# 3. Teste
perl -Ilib -e "use AI::ActivationFunctions; print 'Carregou!\\n';"

# 4. Execute o teste rápido
perl test_quick.pl

# 5. Execute os testes formais
prove -Ilib t/

# 6. Execute o exemplo
perl examples/simple.pl
