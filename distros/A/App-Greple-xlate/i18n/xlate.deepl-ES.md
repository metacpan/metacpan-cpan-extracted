# NAME

App::Greple::xlate - módulo de traducción para greple

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.01

# DESCRIPTION

**Greple** **xlate**: el módulo busca los bloques de texto deseados y los sustituye por el texto traducido. El motor principal es GPT-5.5 (`llm/gpt5.pm`), que ejecuta el comando [llm](https://llm.datasette.io/); También se incluyen DeepL (`deepl.pm`) y motores heredados basados en **gpty**.

Las traducciones se almacenan en caché por archivo, por lo que volver a ejecutar un comando no supone ningún coste para el texto que no haya cambiado. Cuando se edita un documento, solo se envían de nuevo a la API los párrafos modificados; además, un motor sensible al contexto recibe las traducciones circundantes, el texto fuente sin procesar que rodea el cambio y la versión anterior del párrafo editado, de modo que la nueva traducción mantiene la redacción establecida (véase **--xlate-context-window**). Las cadenas sensibles pueden ocultarse antes de la transmisión (véase ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)).

Si deseas traducir bloques de texto normales en un documento escrito en el estilo pod de Perl, utiliza el comando **greple** con los módulos `--xlate-engine gpt5` y `perl` de la siguiente manera:

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

En este comando, la cadena de patrones `^([\w\pP].*\n)+` significa líneas consecutivas que comienzan con letras alfanuméricas y de puntuación. Este comando muestra resaltada el área a traducir. La opción **--all** se utiliza para producir el texto completo.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

A continuación, añade la opción `--xlate` para traducir el área seleccionada. De este modo, el sistema localizará las secciones deseadas y las sustituirá por el resultado del motor de traducción.

Por defecto, el texto original y traducido se imprime en el formato "marcador de conflicto" compatible con [git(1)](http://man.he.net/man1/git). Usando el formato `ifdef`, puede obtener la parte deseada mediante el comando [unifdef(1)](http://man.he.net/man1/unifdef) fácilmente. El formato de salida puede especificarse mediante la opción **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Si desea traducir todo el texto, utilice la opción **--match-all**. Es un atajo para especificar el patrón `(?s).+` que coincide con todo el texto.

Los datos en formato de marcador de conflicto pueden visualizarse en estilo lado a lado mediante el comando [sdif](https://metacpan.org/pod/App%3A%3Asdif) con la opción `-V`. Dado que no tiene sentido comparar cadena por cadena, se recomienda la opción `--no-cdif`. Si no necesita colorear el texto, especifique `--no-textcolor` (o `--no-tc`).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

El procesamiento se realiza en unidades especificadas, pero en el caso de una secuencia de varias líneas de texto no vacías, se convierten juntas en una sola línea. Esta operación se realiza del siguiente modo:

- Se eliminan los espacios en blanco al principio y al final de cada línea.
- Si una línea termina con un carácter de puntuación de ancho completo, concaténela con la línea siguiente.
- Si una línea termina con un carácter de ancho completo y la línea siguiente comienza con un carácter de ancho completo, concatene las líneas.
- Si el final o el principio de una línea no es un carácter de ancho completo, concaténelas insertando un carácter de espacio.

Los datos de la caché se gestionan en función del texto normalizado, por lo que aunque se realicen modificaciones que no afecten a los resultados de la normalización, los datos de traducción almacenados en la caché seguirán siendo efectivos.

Este proceso de normalización sólo se realiza para el primer patrón (0) y los patrones pares. Por lo tanto, si se especifican dos patrones como los siguientes, el texto que coincida con el primer patrón se procesará después de la normalización, y no se realizará ningún proceso de normalización en el texto que coincida con el segundo patrón.

    greple -Mxlate -E normalized -E not-normalized

Por lo tanto, utilice el primer patrón para texto que deba procesarse combinando varias líneas en una sola, y utilice el segundo patrón para texto preformateado. Si no hay texto que coincidir en el primer patrón, utilice un patrón que no coincida con nada, como `(?!)`.

# MASKING

En ocasiones, hay partes del texto que no desea traducir. Por ejemplo, las etiquetas de los archivos markdown. DeepL sugiere que, en tales casos, la parte del texto que debe excluirse se convierta en etiquetas XML, se traduzca y, una vez finalizada la traducción, se restaure. Para ello, es posible especificar las partes que no deben traducirse.

    --xlate-setopt maskfile=MASKPATTERN

Esto interpretará cada línea del archivo `MASKPATTERN` como una expresión regular, traducirá las cadenas que coincidan con ella y revertirá después del procesamiento. Las líneas que comienzan con `#` se ignoran.

Los patrones complejos pueden escribirse en varias líneas con saltos de línea escapados mediante la barra invertida.

Cómo se transforma el texto mediante el enmascaramiento puede verse con la opción **--xlate-mask**.

El enmascaramiento evita que se traduzcan los elementos de marcado. Para ocultar cadenas sensibles al propio servicio de traducción, consulta ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates); ambas opciones pueden utilizarse conjuntamente.

Esta interfaz es experimental y está sujeta a cambios en el futuro.

# ANONYMIZATION AND TEMPLATES

Las cadenas sensibles pueden ocultarse antes de enviarlas a la API de traducción y restaurarse en el resultado. Hay tres fuentes de reglas de anonimización disponibles: un archivo de diccionario (**--xlate-anonymize**), marcas en línea en el propio documento (**--xlate-anonymize-mark**) y valores de front matter YAML (**--xlate-frontmatter**). Cada cadena se sustituye por una etiqueta de categoría, como `<person id=1 />`, durante la transmisión. La ocultación se aplica únicamente a la transmisión a la API: los archivos de caché locales almacenan el texto sin formato restaurado. Utiliza **--xlate-dryrun** para comprobar exactamente qué se transmitiría.

Para los documentos de formulario (informes trimestrales y similares), define los actores desde el principio y haz referencia a ellos en el cuerpo:

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

Traduce la plantilla una vez por idioma con `--xlate-template` (y `--xlate-frontmatter` cuando los valores se mantengan en el archivo); a continuación, genera cada caso con **pandoc-embedz** en modo autónomo; los valores bajo `global:` en una configuración externa nunca llegan a la API de traducción:

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

En el caso de las marcas en línea, proporcionar una configuración de definición de macro hace que la misma plantilla traducida muestre los nombres reales o una versión censurada:

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

Excluye los bloques «embedz» de la traducción cuando un documento los contenga:

    --exclude '^```embedz\n(?s:.*?)^```\n'

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Invoca el proceso de traducción para cada área coincidente.

    Sin esta opción, **greple** se comporta como un comando de búsqueda normal. Por lo tanto, puede comprobar qué parte del archivo será objeto de la traducción antes de invocar el trabajo real.

    El resultado del comando va a la salida estándar, así que rediríjalo al archivo si es necesario, o considere usar el módulo [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    La opción **--xlate** llama a la opción **--xlate-color** con la opción **--color=nunca**.

    Con la opción **--xlate-fold**, el texto convertido se dobla por el ancho especificado. La anchura por defecto es 70 y puede ajustarse con la opción **--xlate-fold-width**. Se reservan cuatro columnas para la operación de repliegue, por lo que cada línea puede contener 74 caracteres como máximo.

- **--xlate-engine**=_engine_

    Especifica el motor de traducción que se va a utilizar.

    En este momento, están disponibles los siguientes motores

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    Los módulos del motor se buscan primero en los espacios de nombres del backend (`llm`, luego `gpty`), y después directamente bajo `App::Greple::xlate`. Así, `gpt5` carga `App::Greple::xlate::llm::gpt5`, que a su vez llama al comando `llm`, mientras que `gpt4o` recurre a `App::Greple::xlate::gpty::gpt4o`. Utiliza `--xlate-setopt backend=gpty` para forzar un backend específico.

- **--xlate-labor**
- **--xlabor**

    En lugar de llamar al motor de traducción, se espera que trabajen para. Después de preparar el texto a traducir, se copia en el portapapeles. Se espera que los pegue en el formulario, copie el resultado en el portapapeles y pulse Retorno.

- **--xlate-to** (Default: `EN-US`)

    Especifica el idioma de destino. Los motores LLM aceptan cualquier nombre o código de idioma que el modelo comprenda; este se interpolará en la solicitud de traducción. Puedes obtener los idiomas disponibles mediante el comando `deepl languages` cuando utilices el motor **DeepL**.

- **--xlate-from** (Default: `ORIGINAL`)

    Etiqueta utilizada para el texto original en los formatos de salida `conflict`, `colon` y `ifdef`. Con el motor **DeepL**, también se pasa un valor no predeterminado como idioma de origen.

- **--xlate-format**=_format_ (Default: `conflict`)

    Especifique el formato de salida del texto original y traducido.

    Los siguientes formatos distintos de `xtxt` asumen que la parte a traducir es una colección de líneas. De hecho, es posible traducir sólo una parte de una línea, pero especificar un formato distinto de `xtxt` no producirá resultados significativos.

    - **conflict**, **cm**

        El texto original y el convertido se imprimen en formato de marcador de conflicto [git(1)](http://man.he.net/man1/git).

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Puede recuperar el archivo original con el siguiente comando [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        El texto original y el traducido salen en un estilo contenedor personalizado de markdown.

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

        El número de dos puntos es 7 por defecto. Si especifica una secuencia de dos puntos como `:::::`, se utiliza en lugar de 7 dos puntos.

    - **ifdef**

        El texto original y el convertido se imprimen en formato [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Puede recuperar sólo el texto japonés mediante el comando **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        El texto original y el convertido se imprimen separados por una sola línea en blanco. Para `espacio+`, también se imprime una nueva línea después del texto convertido.

    - **xtxt**

        Si el formato es `xtxt` (texto traducido) o desconocido, sólo se imprime el texto traducido.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Especifica la longitud máxima del texto que se enviará a la API de una sola vez. El valor por defecto 0 se refiere al límite propio del motor: para el servicio gratuito de DeepL, este es de 128K para la API (**--xlate**) y de 5000 para la interfaz del portapapeles (**--xlate-labor**). Es posible que puedas modificar estos valores si utilizas el servicio Pro.

- **--xlate-maxline**=_n_ (Default: 0)

    Especifique el número máximo de líneas de texto que se enviarán a la API de una sola vez.

    Establezca este valor en 1 si desea traducir una línea cada vez. Esta opción tiene prioridad sobre la opción `--xlate-maxlen`.

- **--xlate-prompt**=_text_

    Especifica una indicación personalizada que se enviará al motor de traducción. Esta opción está disponible para los motores LLM (`gpt3`, `gpt4o`, `gpt5`), pero no para DeepL. Puedes personalizar el comportamiento de la traducción proporcionando instrucciones específicas al modelo de IA. Si la indicación contiene `%s`, se sustituirá por el nombre del idioma de destino.

- **--xlate-context**=_text_

    Especifique la información de contexto adicional que se enviará al motor de traducción. Esta opción puede utilizarse varias veces para proporcionar varias cadenas de contexto. La información de contexto ayuda al motor de traducción a comprender el contexto y producir traducciones más precisas.

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    Número de bloques traducidos circundantes que se pasan como contexto de referencia al volver a traducir los bloques modificados (por defecto, 2). El contexto también incluye el texto fuente sin procesar que rodea la región modificada (encabezados, estructura de listas, pies de foto) y, cuando esté disponible, la versión anterior del texto modificado recuperada de la caché, de modo que se conserve la redacción no modificada. Establecer en 0 para desactivar por completo la traducción sensible al contexto. Ten en cuenta que cada región modificada se traduce en su propia llamada a la API y que el contexto puede sumar hasta unos 8000 caracteres a la indicación del sistema, por lo que la traducción sensible al contexto implica un coste adicional a cambio de la coherencia.

- **--xlate-cache-seed**=_file_

    Inicializa la caché de un nuevo documento a partir del archivo de caché de otro documento. Resulta útil para informes periódicos: se inicializa la caché del nuevo número con la del número anterior, de modo que los párrafos que no han cambiado no se vuelven a traducir y los párrafos editados conservan la redacción del número anterior. La inicialización solo se utiliza cuando la caché de destino está vacía; de lo contrario, se ignora y se muestra una advertencia. Con el valor predeterminado `--xlate-cache=auto`, especificar una inicialización también implica crear el archivo de caché del nuevo documento.

- **--xlate-anonymize**=_file_

    Anonimiza las cadenas sensibles antes de enviarlas a la API de traducción y las restaura en la salida. El archivo de diccionario proporciona una entrada por elemento: en JSON (canónico, generable por máquina)

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    o en un formato de línea simple (`category pattern`, `/.../` para expresiones regulares). Cada elemento se sustituye por una etiqueta de categoría como `<person id=1 />`; a la misma cadena siempre se le asigna la misma etiqueta, de modo que el modelo puede llevar un registro de quién es quién. Los campos JSON desconocidos se ignoran, por lo que los generadores (por ejemplo, un LLM local que extraiga entidades) pueden añadir sus propias anotaciones. La categoría `lit` está reservada. Los archivos de caché locales siguen almacenando el texto sin formato restaurado: el objetivo de ocultación se limita únicamente a la transmisión a través de la API.

    Se puede generar un diccionario mediante una herramienta externa —por ejemplo, un modelo local que extraiga entidades sensibles—:

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    Se tolera la presencia de un BOM UTF-8 en el archivo. Los valores en formato de línea de encabezado pueden incluir un comentario al final, pero solo en su propia línea, no después del valor.

- **--xlate-anonymize-mark**\[=_regex_\]

    Recopila las entradas de anonimización a partir de las marcas en línea del propio documento. Marca la primera aparición como `{{ person("山田太郎") }}` y todas las apariciones de la cadena en todo el documento quedarán anonimizadas. La marca en sí permanece en el texto original y en la traducción, por lo que un documento también puede procesarse mediante un procesador de macros al estilo Jinja2 (define la macro `person` para mostrar o ocultar el nombre). Un _regex_ personalizado debe contener capturas con nombre `(?<category>...)` y `(?<text>...)`.

    Ten en cuenta que, con una opción de valor opcional como esta, se tomaría como valor cualquier argumento de archivo que le siguiera: escribe `--xlate-anonymize-mark=` (con un `=` al final) cuando utilices la notación predeterminada.

    Se pueden configurar notaciones alternativas, por ejemplo, `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'` para marcas de estilo `@@person:NAME@@`, o un formato de comentario HTML que permanece invisible en el Markdown renderizado. Las reglas de marcado se recopilan por documento: una cadena marcada en un archivo de entrada no se oculta en otro archivo de la misma ejecución (a diferencia de los valores de la parte inicial, que se acumulan entre archivos).

- **--xlate-template**\[=_regex_\]

    Trata las expresiones de plantilla (por defecto: Jinja2 `{{ ... }}`, `{% ... %}`, `{# ... #}`) como marcadores de posición opacos: indica al modelo que las copie sin cambios y verifica, por bloque, que la respuesta contenga exactamente las mismas expresiones, cada una el mismo número de veces. Su orden puede cambiar, ya que la traducción las reordena legítimamente para seguir el orden de las palabras del idioma de destino. Una expresión errónea interrumpe la ejecución; la caché se guarda en un punto de control y se congela, por lo que no se pierde nada de lo que se haya pagado.

    Ten en cuenta que, con una opción de valor opcional como esta, se tomaría como valor cualquier argumento de archivo que le siguiera: escribe `--xlate-template=` (con un `=` al final) cuando utilices la notación predeterminada.

- **--xlate-frontmatter**

    Trata un bloque que comience por `---` ... `---` como «front matter» de YAML: exclúyelo de la traducción y de los fragmentos de contexto de la fase 2, y añade sus valores planos `key: value` a las reglas de anonimización (categoría `var`) como medida de seguridad. Si hay varios archivos de entrada, los valores recopilados se acumulan (peciando por exceso de cautela).

    Deja siempre una línea en blanco después del cierre `---`. Con un patrón de coincidencia de estilo párrafo, el front matter que se adentra directamente en el cuerpo del texto forma un bloque que abarca ambos y que la exclusión no puede suprimir (en ese caso se muestra una advertencia); los valores siguen estando anonimizados, pero la información preliminar en sí se enviaría a traducir.

- **--xlate-glossary**=_glossary_

    Especifique un ID de glosario que se utilizará para la traducción. Esta opción sólo está disponible cuando se utiliza el motor DeepL. El ID del glosario debe obtenerse de su cuenta de DeepL y garantiza la traducción coherente de términos específicos.

- **--xlate-dryrun**

    No llames a la API de traducción; en su lugar, muestra, a través de la pantalla de progreso, cada carga útil exactamente tal y como se transmitiría (tras la anonimización y el enmascaramiento). Resulta útil para comprobar qué sale de la máquina y para estimar el coste de una ejecución.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Consulta el resultado de la traducción en tiempo real en la salida de STDERR. La carga útil `From` se muestra tal y como se transmite, tras la anonimización y el enmascaramiento.

- **--xlate-stripe**

    Utilice el módulo [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) para mostrar las partes coincidentes en forma de rayas de cebra. Esto es útil cuando las partes coincidentes están conectadas espalda con espalda.

    La paleta de colores cambia según el color de fondo del terminal. Si desea especificarlo explícitamente, puede utilizar **--xlate-stripe-light** o **--xlate-stripe-dark**.

- **--xlate-mask**

    Realiza la función de enmascaramiento y muestra el texto convertido tal cual sin restaurar.

- **--match-all**

    Establece todo el texto del fichero como área de destino.

- **--lineify-cm**
- **--lineify-colon**

    En el caso de los formatos `cm` y `colon`, la salida se divide y formatea línea por línea. Por lo tanto, si sólo se quiere traducir una parte de una línea, no se puede obtener el resultado esperado. Estos filtros corrigen la salida que se corrompe al traducir parte de una línea a la salida normal línea por línea.

    En la implementación actual, si se traducen varias partes de una línea, se emiten como líneas independientes.

# CACHE OPTIONS

El módulo **xlate** puede almacenar en caché el texto traducido de cada fichero y leerlo antes de la ejecución para eliminar la sobrecarga de preguntar al servidor. Con la estrategia de caché por defecto `auto`, mantiene los datos de caché sólo cuando el archivo de caché existe para el archivo de destino.

Utilice **--xlate-cache=clear** para iniciar la gestión de la caché o para limpiar todos los datos de caché existentes. Una vez ejecutado con esta opción, se creará un nuevo archivo de caché si no existe y se mantendrá automáticamente después.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Mantener el archivo de caché si existe.

    - `create`

        Crear un archivo de caché vacío y salir.

    - `always`, `yes`, `1`

        Mantener caché de todos modos hasta que el destino sea un archivo normal.

    - `clear`

        Borrar primero los datos de la caché.

    - `never`, `no`, `0`

        No utilizar nunca el archivo de caché aunque exista.

    - `accumulate`

        Por defecto, los datos no utilizados se eliminan del archivo de caché. Si no desea eliminarlos y mantenerlos en el archivo, utilice `acumular`.
- **--xlate-update**

    Esta opción obliga a actualizar el archivo de caché aunque no sea necesario.

# COMMAND LINE INTERFACE

Puede utilizar fácilmente este módulo desde la línea de comandos mediante el comando `xlate` incluido en la distribución. Consulte la página del manual `xlate` para más información.

El comando `xlate` admite opciones largas al estilo GNU como `--to-lang`, `--from-lang`, `--engine` y `--file`. Utilice `xlate -h` para ver todas las opciones disponibles.

El comando `xlate` funciona conjuntamente con el entorno Docker, por lo que incluso si no tiene nada instalado a mano, puede utilizarlo siempre que Docker esté disponible. Utilice la opción `-D` o `-C`.

Las operaciones Docker son manejadas por [App::dozo](https://metacpan.org/pod/App%3A%3Adozo), que también se puede utilizar como un comando independiente. El comando `dozo` es compatible con el archivo de configuración `.dozorc` para la configuración persistente del contenedor.

Además, como se proporcionan makefiles para varios estilos de documento, la traducción a otros idiomas es posible sin especificación especial. Utilice la opción `-M`.

También puedes combinar las opciones Docker y `make` para poder ejecutar `make` en un entorno Docker.

Ejecutar como `xlate -C` lanzará un shell con el repositorio git de trabajo actual montado.

Lea el artículo japonés en la sección ["SEE TAMBIÉN"](#see-también) para más detalles.

# EMACS

Cargue el fichero `xlate.el` incluido en el repositorio para usar el comando `xlate` desde el editor Emacs. La función `xlate-region` traduce la región dada. El idioma por defecto es `EN-US` y puede especificar el idioma invocándolo con el argumento prefijo.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Establezca su clave de autenticación para el servicio DeepL.

- OPENAI\_API\_KEY

    Clave de autenticación de OpenAI, utilizada por los motores heredados **gpty**. El motor **gpt5** basado en `llm` también lee esta variable, pero las claves almacenadas con `llm keys set openai` también funcionan.

- GREPLE\_XLATE\_CACHE

    Establece la estrategia de caché por defecto (véase ["CACHE OPTIONS"](#cache-options)).

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Instala la herramienta de línea de comandos para el motor que utilices: `llm` para el motor **gpt5**, `deepl` para DeepL, `gpty` para los motores GPT heredados.

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm), [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - Corredor Docker genérico utilizado por xlate para operaciones de contenedor.

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Vea el manual **greple** para los detalles sobre el patrón de texto objetivo. Utilice las opciones **--inside**, **--outside**, **--include**, **--exclude** para limitar el área de coincidencia.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Puede utilizar el módulo `-Mupdate` para modificar archivos según el resultado del comando **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Utilice **sdif** para mostrar el formato del marcador de conflicto junto con la opción **-V**.

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Uso del módulo Greple **stripe** mediante la opción **--xlate-stripe**.

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Imagen de contenedor Docker.

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    La biblioteca `getoptlong.sh` utilizada para el análisis sintáctico de opciones en el script `xlate` y [App::dozo](https://metacpan.org/pod/App%3A%3Adozo).

- [https://llm.datasette.io/](https://llm.datasette.io/)

    El comando `llm` utilizado por el motor **gpt5** para acceder a los modelos LLM.

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Librería Python y comando CLI.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Biblioteca OpenAI Python

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interfaz de línea de comandos de OpenAI

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Módulo Greple para traducir y sustituir sólo las partes necesarias con DeepL API (en japonés)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Generación de documentos en 15 idiomas con el módulo API DeepL (en japonés)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Entorno Docker de traducción automática con DeepL API (en japonés)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
