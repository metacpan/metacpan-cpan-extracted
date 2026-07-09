# NAME

App::Greple::xlate - módulo de soporte de traducción para greple

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.01

# DESCRIPTION

**Greple** **xlate** module encuentra los bloques de texto deseados y los reemplaza por el texto traducido. El motor principal es GPT-5.5 (`llm/gpt5.pm`), que llama al comando [llm](https://llm.datasette.io/); DeepL (`deepl.pm`) y los motores heredados basados en **gpty** también están incluidos.

Las traducciones se almacenan en caché por archivo, por lo que volver a ejecutar un comando no cuesta nada para el texto sin cambios. Cuando se edita un documento, solo los párrafos modificados se envían de nuevo a la API; un motor consciente del contexto también recibe las traducciones circundantes, el texto fuente sin procesar alrededor del cambio y la versión anterior del párrafo editado, de modo que la nueva traducción mantenga la redacción establecida (véase **--xlate-context-window**). Las cadenas sensibles pueden ocultarse antes de la transmisión (véase ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)).

Si desea traducir bloques de texto normales en un documento escrito en el estilo pod de Perl, use el comando **greple** con `--xlate-engine gpt5` y el módulo `perl` así:

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

En este comando, la cadena de patrón `^([\w\pP].*\n)+` significa líneas consecutivas que comienzan con letras alfanuméricas y signos de puntuación. Este comando muestra el área a traducir resaltada. La opción **--all** se utiliza para producir el texto completo.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Luego agregue la opción `--xlate` para traducir el área seleccionada. Entonces, encontrará las secciones deseadas y las reemplazará por la salida del motor de traducción.

De forma predeterminada, el texto original y el traducido se imprimen en el formato de "marcador de conflicto" compatible con [git(1)](http://man.he.net/man1/git). Usando el formato `ifdef`, puede obtener la parte deseada fácilmente con el comando [unifdef(1)](http://man.he.net/man1/unifdef). El formato de salida puede especificarse con la opción **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Si desea traducir todo el texto, use la opción **--match-all**. Este es un atajo para especificar el patrón `(?s).+` que coincide con todo el texto.

Los datos en formato de marcador de conflicto pueden visualizarse en estilo lado a lado con el comando [sdif](https://metacpan.org/pod/App%3A%3Asdif) y la opción `-V`. Dado que no tiene sentido comparar por cadena, se recomienda la opción `--no-cdif`. Si no necesita colorear el texto, especifique `--no-textcolor` (o `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

El procesamiento se realiza en unidades especificadas, pero en el caso de una secuencia de múltiples líneas de texto no vacío, se convierten juntas en una sola línea. Esta operación se realiza de la siguiente manera:

- Eliminar los espacios en blanco al principio y al final de cada línea.
- Si una línea termina con un signo de puntuación de ancho completo, concatenar con la siguiente línea.
- Si una línea termina con un carácter de ancho completo y la siguiente línea comienza con un carácter de ancho completo, concatenar las líneas.
- Si el final o el comienzo de una línea no es un carácter de ancho completo, concatenarlas insertando un espacio.

Los datos de caché se gestionan en función del texto normalizado, por lo que incluso si se realizan modificaciones que no afecten los resultados de la normalización, los datos de traducción en caché seguirán siendo efectivos.

Este proceso de normalización se realiza solo para el primer (índice 0) y los patrones de número par. Por lo tanto, si se especifican dos patrones como se indica a continuación, el texto que coincida con el primer patrón se procesará después de la normalización, y no se realizará ningún proceso de normalización en el texto que coincida con el segundo patrón.

    greple -Mxlate -E normalized -E not-normalized

Por lo tanto, use el primer patrón para el texto que deba procesarse combinando múltiples líneas en una sola línea, y use el segundo patrón para texto preformateado. Si no hay texto que coincida en el primer patrón, use un patrón que no coincida con nada, como `(?!)`.

# MASKING

Ocasionalmente, hay partes del texto que no desea traducir. Por ejemplo, etiquetas en archivos markdown. DeepL sugiere que, en tales casos, la parte del texto a excluir se convierta en etiquetas XML, se traduzca y luego se restaure una vez completada la traducción. Para admitir esto, es posible especificar las partes que se deben enmascarar de la traducción.

    --xlate-setopt maskfile=MASKPATTERN

Esto interpretará cada línea del archivo `MASKPATTERN` como una expresión regular, traducirá las cadenas que coincidan con ella y revertirá después del procesamiento. Las líneas que comienzan con `#` se ignoran.

Un patrón complejo puede escribirse en múltiples líneas con salto de línea escapado con barra invertida.

Cómo se transforma el texto mediante el enmascaramiento puede verse con la opción **--xlate-mask**.

El enmascaramiento protege el marcado para que no se traduzca. Para ocultar cadenas sensibles al propio servicio de traducción, consulte ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates); ambos pueden usarse juntos.

Esta interfaz es experimental y está sujeta a cambios en el futuro.

# ANONYMIZATION AND TEMPLATES

Las cadenas sensibles pueden ocultarse antes de enviarse a la API de traducción y restaurarse en la salida. Hay tres fuentes de reglas de anonimización disponibles: un archivo de diccionario (**--xlate-anonymize**), marcas en línea en el propio documento (**--xlate-anonymize-mark**) y valores de front matter YAML (**--xlate-frontmatter**). Cada cadena se sustituye por una etiqueta de categoría como `<person id=1 />` durante la transmisión. El objetivo de la ocultación es únicamente la transmisión a la API: los archivos de caché locales almacenan el texto sin formato restaurado. Use **--xlate-dryrun** para inspeccionar exactamente qué se transmitiría.

Para documentos de formulario (informes trimestrales y similares), defina los actores al principio y haga referencia a ellos en el cuerpo:

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

Traduzca la plantilla una vez por idioma con `--xlate-template` (y `--xlate-frontmatter` cuando los valores se mantengan en el archivo), luego renderice cada caso con el modo autónomo de **pandoc-embedz**: los valores bajo `global:` en una configuración externa nunca llegan en absoluto a la API de traducción:

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

Para marcas en línea, proporcionar una configuración de definición de macros hace que la misma plantilla traducida renderice los nombres reales o una versión redactada:

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

Excluya los bloques embedz de la traducción cuando un documento los contenga:

    --exclude '^```embedz\n(?s:.*?)^```\n'

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Invoque el proceso de traducción para cada área coincidente.

    Sin esta opción, **greple** se comporta como un comando de búsqueda normal. Así puede comprobar qué parte del archivo será objeto de la traducción antes de iniciar el trabajo real.

    El resultado del comando va a la salida estándar, así que rediríjalo a un archivo si es necesario, o considere usar el módulo [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    La opción **--xlate** llama a la opción **--xlate-color** con la opción **--color=never**.

    Con la opción **--xlate-fold**, el texto convertido se ajusta al ancho especificado. El ancho predeterminado es 70 y puede establecerse con la opción **--xlate-fold-width**. Se reservan cuatro columnas para la operación de run-in, por lo que cada línea puede contener como máximo 74 caracteres.

- **--xlate-engine**=_engine_

    Especifica el motor de traducción que se utilizará.

    En este momento, están disponibles los siguientes motores

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    Los módulos de motor se buscan primero en los espacios de nombres de backend (`llm`, luego `gpty`), y después directamente bajo `App::Greple::xlate`. Por tanto, `gpt5` carga `App::Greple::xlate::llm::gpt5`, que llama al comando `llm`, mientras que `gpt4o` recurre a `App::Greple::xlate::gpty::gpt4o`. Use `--xlate-setopt backend=gpty` para forzar un backend específico.

- **--xlate-labor**
- **--xlabor**

    En lugar de llamar al motor de traducción, se espera que usted trabaje manualmente. Después de preparar el texto a traducir, se copia al portapapeles. Se espera que lo pegue en el formulario, copie el resultado al portapapeles y presione regresar.

- **--xlate-to** (Default: `EN-US`)

    Especifique el idioma de destino. Los motores LLM aceptan cualquier nombre o código de idioma que el modelo entienda; se interpola en el prompt de traducción. Puede obtener los idiomas disponibles con el comando `deepl languages` cuando use el motor **DeepL**.

- **--xlate-from** (Default: `ORIGINAL`)

    Etiqueta utilizada para el texto original en los formatos de salida `conflict`, `colon` y `ifdef`. Con el motor **DeepL**, un valor no predeterminado también se pasa como idioma de origen.

- **--xlate-format**=_format_ (Default: `conflict`)

    Especifique el formato de salida para el texto original y el traducido.

    Los siguientes formatos distintos de `xtxt` asumen que la parte a traducir es una colección de líneas. De hecho, es posible traducir solo una parte de una línea, pero especificar un formato distinto de `xtxt` no producirá resultados significativos.

    - **conflict**, **cm**

        El texto original y el convertido se imprimen en formato de marcadores de conflicto de [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Puede recuperar el archivo original con el siguiente comando [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        El texto original y el traducido se muestran en un estilo de contenedor personalizado de markdown.

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        El texto anterior se traducirá a lo siguiente en HTML.

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        El número de dos puntos es 7 por defecto. Si especifica una secuencia de dos puntos como `:::::`, se usa en lugar de 7 dos puntos.

    - **ifdef**

        El texto original y el convertido se imprimen en formato [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Puede recuperar solo el texto japonés con el comando **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        El texto original y el convertido se imprimen separados por una sola línea en blanco. Para `space+`, también se imprime una nueva línea después del texto convertido.

    - **xtxt**

        Si el formato es `xtxt` (texto traducido) o desconocido, solo se imprime el texto traducido.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Especifique la longitud máxima del texto que se enviará a la API de una vez. El valor predeterminado 0 significa el límite propio del motor: para el servicio de cuenta gratuita de DeepL, es 128K para la API (**--xlate**) y 5000 para la interfaz del portapapeles (**--xlate-labor**). Es posible que pueda cambiar estos valores si utiliza el servicio Pro.

- **--xlate-maxline**=_n_ (Default: 0)

    Especifique el número máximo de líneas de texto que se enviarán a la API de una vez.

    Establezca este valor en 1 si desea traducir una línea a la vez. Esta opción tiene prioridad sobre la opción `--xlate-maxlen`.

- **--xlate-prompt**=_text_

    Especifique un prompt personalizado para enviarlo al motor de traducción. Esta opción está disponible para los motores LLM (`gpt3`, `gpt4o`, `gpt5`), pero no para DeepL. Puede personalizar el comportamiento de la traducción proporcionando instrucciones específicas al modelo de IA. Si el prompt contiene `%s`, se reemplazará por el nombre del idioma de destino.

- **--xlate-context**=_text_

    Especifique información de contexto adicional que se enviará al motor de traducción. Esta opción se puede usar varias veces para proporcionar múltiples cadenas de contexto. La información de contexto ayuda al motor de traducción a comprender el trasfondo y producir traducciones más precisas.

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    Número de bloques traducidos circundantes que se pasan como contexto de referencia al volver a traducir bloques modificados (predeterminado 2). El contexto también incluye el texto fuente sin procesar alrededor de la región modificada (encabezados, estructura de listas, leyendas) y, cuando está disponible, la versión anterior del texto modificado recuperada de la caché, de modo que se conserve la redacción sin cambios. Establézcalo en 0 para desactivar por completo la traducción con conocimiento del contexto. Tenga en cuenta que cada región modificada se traduce en su propia llamada a la API y que el contexto puede añadir hasta unos 8000 caracteres al prompt del sistema, por lo que la traducción con conocimiento del contexto intercambia algo de coste adicional por coherencia.

- **--xlate-cache-seed**=_file_

    Inicialice la caché de un documento nuevo a partir del archivo de caché de otro documento. Útil para informes periódicos: inicialice la caché del nuevo número con la del número anterior, de modo que los párrafos sin cambios no se vuelvan a traducir y los párrafos editados conserven la redacción del número anterior. La semilla se usa solo cuando la caché de destino está vacía; de lo contrario, se ignora con una advertencia. Con el `--xlate-cache=auto` predeterminado, especificar una semilla también implica crear el archivo de caché del nuevo documento.

- **--xlate-anonymize**=_file_

    Anonimice las cadenas sensibles antes de que se envíen a la API de traducción y restáurelas en la salida. El archivo de diccionario proporciona una entrada por elemento: en JSON (canónico, generable por máquina)

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    o en un formato de línea simple (`category pattern`, `/.../` para regex). Cada elemento se reemplaza por una etiqueta de categoría como `<person id=1 />`; la misma cadena siempre obtiene la misma etiqueta, por lo que el modelo puede llevar la cuenta de quién es quién. Los campos JSON desconocidos se ignoran, por lo que los generadores (por ejemplo, un LLM local que extrae entidades) pueden añadir sus propias anotaciones. La categoría `lit` está reservada. Los archivos de caché locales siguen almacenando texto plano restaurado: el objetivo de la ocultación es únicamente la transmisión a la API.

    Un diccionario puede generarse mediante una herramienta externa; por ejemplo, un modelo local que extrae entidades sensibles:

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    Se tolera una BOM UTF-8 en el archivo. Los valores en el formato de línea de front matter pueden llevar un comentario final solo en su propia línea, no después del valor.

- **--xlate-anonymize-mark**\[=_regex_\]

    Recoja entradas de anonimización de marcas en línea en el propio documento. Marque la primera aparición como `{{ person("山田太郎") }}` y cada aparición de la cadena en todo el documento se anonimizará. La marca en sí permanece en el origen y en la traducción, de modo que un documento también pueda ser procesado por un procesador de macros de estilo Jinja2 (defina la macro `person` para imprimir o redactar el nombre). Un _regex_ personalizado debe contener capturas con nombre `(?<category>...)` y `(?<text>...)`.

    Tenga en cuenta que, con una opción de valor opcional como esta, un argumento de archivo siguiente se tomaría como el valor: escriba `--xlate-anonymize-mark=` (con un `=` final) cuando use la notación predeterminada.

    Se pueden configurar notaciones alternativas, por ejemplo `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'` para marcas de estilo `@@person:NAME@@`, o una forma de comentario HTML que permanezca invisible en el Markdown renderizado. Las reglas de marca se recopilan por documento: una cadena marcada en un archivo de entrada no se oculta en otro archivo de la misma ejecución (a diferencia de los valores de front matter, que se acumulan entre archivos).

- **--xlate-template**\[=_regex_\]

    Trate las expresiones de plantilla (predeterminado: Jinja2 `{{ ... }}`, `{% ... %}`, `{# ... #}`) como marcadores de posición opacos: indique al modelo que las copie sin cambios y verifique, por bloque, que la respuesta contenga exactamente las mismas expresiones, cada una el mismo número de veces. Su orden puede cambiar, ya que la traducción las reordena legítimamente para seguir el orden de palabras del idioma de destino. Una expresión dañada aborta la ejecución; la caché se guarda en un punto de control y se congela, de modo que no se pierde nada pagado.

    Tenga en cuenta que, con una opción de valor opcional como esta, un argumento de archivo siguiente se tomaría como el valor: escriba `--xlate-template=` (con un `=` final) al usar la notación predeterminada.

- **--xlate-frontmatter**

    Trate un bloque inicial `---` ... `---` como front matter YAML: exclúyalo de la traducción y de los fragmentos de contexto de la fase 2, y agregue sus valores planos `key: value` a las reglas de anonimización (categoría `var`) como red de seguridad. Con múltiples archivos de entrada, los valores recopilados se acumulan (pecando por exceso de ocultación).

    Deje siempre una línea en blanco después del `---` de cierre. Con un patrón de coincidencia de estilo párrafo, el front matter que se une directamente al texto del cuerpo forma un bloque superpuesto que la exclusión no puede suprimir (en ese caso se imprime una advertencia); los valores siguen anonimizándose, pero el propio front matter se enviaría para traducción.

- **--xlate-glossary**=_glossary_

    Especifique un ID de glosario que se utilizará para la traducción. Esta opción solo está disponible al usar el motor de DeepL. El ID de glosario debe obtenerse de su cuenta de DeepL y garantiza una traducción coherente de términos específicos.

- **--xlate-dryrun**

    No llame a la API de traducción; en su lugar, muestre, a través de la visualización de progreso, cada payload exactamente como se transmitiría (después de la anonimización y el enmascaramiento). Útil para comprobar qué sale de la máquina y para estimar el coste de una ejecución.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vea el resultado de la traducción en tiempo real en la salida STDERR. El payload `From` se muestra tal como se transmitió, después de la anonimización y el enmascaramiento.

- **--xlate-stripe**

    Use el módulo [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) para mostrar la parte coincidente con un estilo de rayas tipo cebra. Esto es útil cuando las partes coincidentes están conectadas consecutivamente.

    La paleta de colores se cambia según el color de fondo de la terminal. Si desea especificarlo explícitamente, puede usar **--xlate-stripe-light** o **--xlate-stripe-dark**.

- **--xlate-mask**

    Realice la función de enmascaramiento y muestre el texto convertido tal cual sin restauración.

- **--match-all**

    Establezca todo el texto del archivo como área objetivo.

- **--lineify-cm**
- **--lineify-colon**

    En el caso de los formatos `cm` y `colon`, la salida se divide y se formatea línea por línea. Por lo tanto, si solo se traduce una parte de una línea, no se puede obtener el resultado esperado. Estos filtros corrigen la salida que se corrompe al traducir parte de una línea a una salida normal línea por línea.

    En la implementación actual, si se traducen múltiples partes de una línea, se generan como líneas independientes.

# CACHE OPTIONS

El módulo **xlate** puede almacenar en caché el texto de la traducción para cada archivo y leerlo antes de la ejecución para eliminar la sobrecarga de consultar al servidor. Con la estrategia de caché predeterminada `auto`, mantiene los datos de la caché solo cuando el archivo de caché existe para el archivo de destino.

Use **--xlate-cache=clear** para iniciar la gestión de la caché o para limpiar todos los datos de caché existentes. Una vez ejecutado con esta opción, se creará un nuevo archivo de caché si no existe y luego se mantendrá automáticamente.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Mantenga el archivo de caché si existe.

    - `create`

        Cree un archivo de caché vacío y salga.

    - `always`, `yes`, `1`

        Mantén la caché de todos modos siempre que el destino sea un archivo normal.

    - `clear`

        Borra primero los datos de la caché.

    - `never`, `no`, `0`

        Nunca uses el archivo de caché aunque exista.

    - `accumulate`

        Por defecto, los datos no utilizados se eliminan del archivo de caché. Si no quieres eliminarlos y prefieres mantenerlos en el archivo, usa `accumulate`.
- **--xlate-update**

    Esta opción fuerza la actualización del archivo de caché aunque no sea necesaria.

# COMMAND LINE INTERFACE

Puedes usar fácilmente este módulo desde la línea de comandos utilizando el comando `xlate` incluido en la distribución. Consulta la página del manual `xlate` para su uso.

El comando `xlate` admite opciones largas al estilo GNU como `--to-lang`, `--from-lang`, `--engine` y `--file`. Use `xlate -h` para ver todas las opciones disponibles.

El comando `xlate` funciona en conjunto con el entorno Docker, por lo que, incluso si no tienes nada instalado localmente, puedes usarlo siempre que Docker esté disponible. Usa la opción `-D` o `-C`.

Las operaciones de Docker son manejadas por [App::dozo](https://metacpan.org/pod/App%3A%3Adozo), que también puede usarse como un comando independiente. El comando `dozo` admite el archivo de configuración `.dozorc` para ajustes persistentes del contenedor.

Además, dado que se proporcionan makefiles para varios estilos de documentos, es posible la traducción a otros idiomas sin especificaciones especiales. Usa la opción `-M`.

También puedes combinar las opciones Docker y `make` para poder ejecutar `make` en un entorno Docker.

Ejecutar como `xlate -C` iniciará una shell con el repositorio git de trabajo actual montado.

Lee el artículo en japonés en la sección ["SEE ALSO"](#see-also) para más detalles.

# EMACS

Carga el archivo `xlate.el` incluido en el repositorio para usar el comando `xlate` desde el editor Emacs. La función `xlate-region` traduce la región indicada. El idioma predeterminado es `EN-US` y puedes especificar el idioma invocándola con un argumento prefijo.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Configura tu clave de autenticación para el servicio DeepL.

- OPENAI\_API\_KEY

    Clave de autenticación de OpenAI, utilizada por los motores heredados **gpty**. El motor **gpt5** basado en `llm` también lee esta variable, pero las claves almacenadas con `llm keys set openai` también funcionan.

- GREPLE\_XLATE\_CACHE

    Configura la estrategia de caché predeterminada (consulta ["CACHE OPTIONS"](#cache-options)).

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Instala la herramienta de línea de comandos para el motor que uses: `llm` para el motor **gpt5**, `deepl` para DeepL, `gpty` para los motores GPT heredados.

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm), [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - Ejecutor genérico de Docker utilizado por xlate para operaciones de contenedor

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Consulta el manual **greple** para más detalles sobre el patrón de texto objetivo. Usa las opciones **--inside**, **--outside**, **--include**, **--exclude** para limitar el área de coincidencia.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Puedes usar el módulo `-Mupdate` para modificar archivos con el resultado del comando **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Usa **sdif** para mostrar el formato de marcador de conflicto junto con la opción **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Módulo de Greple **stripe** usado con la opción **--xlate-stripe**.

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Imagen de contenedor Docker.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    La biblioteca `getoptlong.sh` utilizada para el análisis de opciones en el script `xlate` y [App::dozo](https://metacpan.org/pod/App%3A%3Adozo).

- [https://llm.datasette.io/](https://llm.datasette.io/)

    El comando `llm` utilizado por el motor **gpt5** para acceder a modelos LLM.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Biblioteca de Python y comando CLI de DeepL.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Biblioteca de Python de OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interfaz de línea de comandos de OpenAI

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Módulo de Greple para traducir y reemplazar solo las partes necesarias con la API de DeepL (en japonés)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Generación de documentos en 15 idiomas con el módulo de la API de DeepL (en japonés)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Entorno Docker de traducción automática con la API de DeepL (en japonés)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
