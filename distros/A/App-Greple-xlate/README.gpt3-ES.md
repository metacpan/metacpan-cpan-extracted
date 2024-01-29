# NAME

App::Greple::xlate - módulo de soporte de traducción para greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.29

# DESCRIPTION

El módulo **xlate** de **Greple** encuentra los bloques de texto deseados y los reemplaza por el texto traducido. Actualmente, los módulos DeepL (`deepl.pm`) y ChatGPT (`gpt3.pm`) están implementados como motores de backend.

Si quieres traducir bloques de texto normales en un documento escrito en el estilo pod de Perl, utiliza el comando **greple** con los módulos `xlate::deepl` y `perl` de la siguiente manera:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

En este comando, la cadena de patrón `^(\w.*\n)+` significa líneas consecutivas que comienzan con una letra alfanumérica. Este comando muestra el área que se va a traducir resaltada. La opción **--all** se utiliza para producir todo el texto.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Luego agregue la opción `--xlate` para traducir el área seleccionada. Luego, encontrará las secciones deseadas y las reemplazará por la salida del comando **deepl**.

Por defecto, el texto original y traducido se imprime en el formato de "marcador de conflicto" compatible con [git(1)](http://man.he.net/man1/git). Utilizando el formato `ifdef`, puedes obtener la parte deseada fácilmente con el comando [unifdef(1)](http://man.he.net/man1/unifdef). El formato de salida se puede especificar con la opción **--xlate-format**.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

Si deseas traducir todo el texto, utiliza la opción **--match-all**. Esto es un atajo para especificar el patrón `(?s).+` que coincide con todo el texto.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Invoque el proceso de traducción para cada área coincidente.

    Sin esta opción, **greple** se comporta como un comando de búsqueda normal. Por lo tanto, puede verificar qué parte del archivo será objeto de la traducción antes de invocar el trabajo real.

    El resultado del comando se envía a la salida estándar, así que rediríjalo a un archivo si es necesario, o considere usar el módulo [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate).

    La opción **--xlate** llama a la opción **--xlate-color** con la opción **--color=never**.

    Con la opción **--xlate-fold**, el texto convertido se pliega según el ancho especificado. El ancho predeterminado es 70 y se puede establecer mediante la opción **--xlate-fold-width**. Cuatro columnas están reservadas para la operación de ejecución, por lo que cada línea puede contener como máximo 74 caracteres.

- **--xlate-engine**=_engine_

    Especifica el motor de traducción que se utilizará. Si especificas directamente el módulo del motor, como `-Mxlate::deepl`, no necesitas usar esta opción.

- **--xlate-labor**
- **--xlabor**

    En lugar de llamar al motor de traducción, se espera que trabaje para él. Después de preparar el texto que se va a traducir, se copian al portapapeles. Se espera que los pegue en el formulario, copie el resultado al portapapeles y presione Enter.

- **--xlate-to** (Default: `EN-US`)

    Especifique el idioma de destino. Puede obtener los idiomas disponibles mediante el comando `deepl languages` cuando se utiliza el motor **DeepL**.

- **--xlate-format**=_format_ (Default: `conflict`)

    Especifique el formato de salida para el texto original y traducido.

    - **conflict**, **cm**

        Original and converted text are printed in [git(1)](http://man.he.net/man1/git) conflict marker format.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        Puede recuperar el archivo original con el siguiente comando [sed(1)](http://man.he.net/man1/sed).

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        <<<<<<< HEAD

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        Puede recuperar solo el texto en japonés con el comando **unifdef**:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Original and converted text are printed in [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` format.

    - **xtxt**

        Si el formato es `xtxt` (texto traducido) o desconocido, solo se imprime el texto traducido.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Especifique la longitud máxima del texto a enviar a la API de DeepL. El valor predeterminado es el establecido para la cuenta gratuita de DeepL: 128K para la API (**--xlate**) y 5000 para la interfaz del portapapeles (**--xlate-labor**). Es posible que pueda cambiar estos valores si está utilizando el servicio Pro.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    Vea el resultado de la traducción en tiempo real en la salida STDERR.

- **--match-all**

    Establezca todo el texto del archivo como un área objetivo.

# CACHE OPTIONS

El módulo **xlate** puede almacenar el texto traducido en caché para cada archivo y leerlo antes de la ejecución para eliminar la sobrecarga de preguntar al servidor. Con la estrategia de caché predeterminada `auto`, mantiene los datos en caché solo cuando el archivo de caché existe para el archivo objetivo.

- --cache-clear

    La opción **--cache-clear** se puede utilizar para iniciar la gestión de la caché o para actualizar todos los datos de caché existentes. Una vez ejecutado con esta opción, se creará un nuevo archivo de caché si no existe y luego se mantendrá automáticamente.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Mantenga el archivo de caché si existe.

    - `create`

        Cree un archivo de caché vacío y salga.

    - `always`, `yes`, `1`

        Mantenga la caché de todos modos siempre que el objetivo sea un archivo normal.

    - `clear`

        Borre primero los datos de la caché.

    - `never`, `no`, `0`

        Nunca use el archivo de caché incluso si existe.

    - `accumulate`

        Por defecto, los datos no utilizados se eliminan del archivo de caché. Si no desea eliminarlos y mantenerlos en el archivo, use `accumulate`.

# COMMAND LINE INTERFACE

Puedes usar fácilmente este módulo desde la línea de comandos utilizando el comando `xlate` incluido en el repositorio. Consulta la información de ayuda de `xlate` para ver cómo se utiliza.

# EMACS

Carga el archivo `xlate.el` incluido en el repositorio para usar el comando `xlate` desde el editor Emacs. La función `xlate-region` traduce la región dada. El idioma predeterminado es `EN-US` y puedes especificar el idioma invocándolo con un argumento de prefijo.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Configura tu clave de autenticación para el servicio DeepL.

- OPENAI\_API\_KEY

    Clave de autenticación de OpenAI.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

Debes instalar las herramientas de línea de comandos para DeepL y ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Biblioteca de Python y comando CLI de DeepL.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    Biblioteca de Python de OpenAI

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    Interfaz de línea de comandos de OpenAI

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    Consulta el manual de **greple** para obtener detalles sobre el patrón de texto objetivo. Utiliza las opciones **--inside**, **--outside**, **--include** y **--exclude** para limitar el área de coincidencia.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    Puedes usar el módulo `-Mupdate` para modificar archivos según el resultado del comando **greple**.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Utiliza **sdif** para mostrar el formato de marcador de conflicto junto con la opción **-V**.

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Módulo Greple para traducir y reemplazar solo las partes necesarias con la API de DeepL (en japonés)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Generando documentos en 15 idiomas con el módulo de API de DeepL (en japonés)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Entorno Docker de traducción automática con la API de DeepL (en japonés)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
